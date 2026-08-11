create table if not exists public.project_quotes (
  id uuid primary key default gen_random_uuid(),
  quote_code text not null unique default ((('EVQ-'::text || to_char(now(), 'YYMMDD'::text)) || '-'::text) || upper(substr(replace((gen_random_uuid())::text, '-'::text, ''::text), 1, 6))),
  request_id uuid not null unique references public.project_requests(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  currency text not null default 'AED' check (currency = 'AED'),
  subtotal_aed numeric(12,2) not null check (subtotal_aed >= 0),
  discount_aed numeric(12,2) not null default 0 check (discount_aed >= 0),
  tax_aed numeric(12,2) not null default 0 check (tax_aed >= 0),
  total_aed numeric(12,2) not null check (total_aed >= 0),
  status text not null default 'draft' check (status in ('draft','sent','accepted','rejected','expired','cancelled')),
  pricing_breakdown jsonb not null default '[]'::jsonb,
  scope_snapshot jsonb not null default '{}'::jsonb,
  valid_until timestamptz,
  sent_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists project_quotes_user_status_idx
  on public.project_quotes (user_id, status, created_at desc);
create index if not exists project_quotes_status_idx
  on public.project_quotes (status, created_at desc);

alter table public.project_quotes enable row level security;
revoke all on public.project_quotes from anon;
grant select on public.project_quotes to authenticated;

drop policy if exists project_quotes_select_access on public.project_quotes;
create policy project_quotes_select_access
on public.project_quotes
for select
to authenticated
using (
  ((select auth.uid()) is not null)
  and (
    (select auth.uid()) = user_id
    or (select private.is_evento_staff())
  )
);

create table if not exists public.project_build_queue (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.project_requests(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  quote_id uuid references public.project_quotes(id) on delete set null,
  status text not null default 'pending_payment' check (status in ('pending_payment','queued','building','qa','preview','blocked','completed','cancelled')),
  priority integer not null default 100 check (priority between 1 and 1000),
  source_repo text,
  branch_name text,
  preview_url text,
  artifact_url text,
  queued_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists project_build_queue_user_status_idx
  on public.project_build_queue (user_id, status, priority, created_at);
create index if not exists project_build_queue_status_priority_idx
  on public.project_build_queue (status, priority, created_at);

alter table public.project_build_queue enable row level security;
revoke all on public.project_build_queue from anon;
grant select on public.project_build_queue to authenticated;

drop policy if exists project_build_queue_select_access on public.project_build_queue;
create policy project_build_queue_select_access
on public.project_build_queue
for select
to authenticated
using (
  ((select auth.uid()) is not null)
  and (
    (select auth.uid()) = user_id
    or (select private.is_evento_staff())
  )
);

create or replace function public.evento_create_quote_draft_v1(
  p_actor_user_id uuid,
  p_request_id uuid,
  p_subtotal_aed text,
  p_discount_aed text,
  p_tax_aed text,
  p_pricing_breakdown jsonb,
  p_valid_until timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request_user_id uuid;
  v_stage text;
  v_subtotal numeric(12,2);
  v_discount numeric(12,2);
  v_tax numeric(12,2);
  v_total numeric(12,2);
  v_scope jsonb;
  v_quote public.project_quotes%rowtype;
begin
  if not exists (
    select 1 from private.evento_company_memberships m
    where m.user_id=p_actor_user_id and m.active=true and m.role in ('owner','admin','ops','finance')
  ) then raise exception 'staff_permission_required'; end if;

  begin
    v_subtotal := p_subtotal_aed::numeric(12,2);
    v_discount := coalesce(nullif(p_discount_aed,''),'0')::numeric(12,2);
    v_tax := coalesce(nullif(p_tax_aed,''),'0')::numeric(12,2);
  exception when others then
    raise exception 'invalid_amount';
  end;

  if v_subtotal < 0 or v_discount < 0 or v_tax < 0 then raise exception 'invalid_amount'; end if;
  v_total := greatest(v_subtotal - v_discount + v_tax, 0);

  select r.user_id, w.current_stage
  into v_request_user_id, v_stage
  from public.project_requests r
  join public.project_workflows w on w.request_id=r.id
  where r.id=p_request_id
  for update of r,w;

  if v_request_user_id is null then raise exception 'request_not_found'; end if;
  if v_stage not in ('scope_approved','quote_draft','quote_sent') then raise exception 'scope_not_approved'; end if;

  select jsonb_build_object(
    'complexity', a.complexity,
    'scope', a.proposed_scope,
    'scope_ar', a.proposed_scope_ar,
    'risks', a.risks,
    'risks_ar', a.risks_ar,
    'engine_version', a.engine_version
  ) into v_scope
  from public.request_analyses a
  where a.request_id=p_request_id;

  insert into public.project_quotes(
    request_id,user_id,subtotal_aed,discount_aed,tax_aed,total_aed,
    pricing_breakdown,scope_snapshot,valid_until,status,updated_at
  ) values (
    p_request_id,v_request_user_id,v_subtotal,v_discount,v_tax,v_total,
    coalesce(p_pricing_breakdown,'[]'::jsonb),coalesce(v_scope,'{}'::jsonb),
    coalesce(p_valid_until,now()+interval '7 days'),'draft',now()
  )
  on conflict (request_id) do update set
    subtotal_aed=excluded.subtotal_aed,
    discount_aed=excluded.discount_aed,
    tax_aed=excluded.tax_aed,
    total_aed=excluded.total_aed,
    pricing_breakdown=excluded.pricing_breakdown,
    scope_snapshot=excluded.scope_snapshot,
    valid_until=excluded.valid_until,
    status='draft',
    sent_at=null,
    accepted_at=null,
    updated_at=now()
  returning * into v_quote;

  update public.project_workflows
  set current_stage='quote_draft', progress_percent=35,
      estimated_price_aed=v_total, updated_at=now()
  where request_id=p_request_id;

  return jsonb_build_object(
    'quote_id',v_quote.id,
    'quote_code',v_quote.quote_code,
    'status',v_quote.status,
    'total_aed',v_quote.total_aed,
    'valid_until',v_quote.valid_until
  );
end;
$$;

create or replace function public.evento_send_quote_v1(
  p_actor_user_id uuid,
  p_quote_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_quote public.project_quotes%rowtype;
begin
  if not exists (
    select 1 from private.evento_company_memberships m
    where m.user_id=p_actor_user_id and m.active=true and m.role in ('owner','admin','ops','finance')
  ) then raise exception 'staff_permission_required'; end if;

  select * into v_quote
  from public.project_quotes
  where id=p_quote_id
  for update;

  if v_quote.id is null then raise exception 'quote_not_found'; end if;
  if v_quote.status <> 'draft' then raise exception 'quote_not_sendable'; end if;

  update public.project_quotes
  set status='sent', sent_at=now(), updated_at=now()
  where id=p_quote_id;

  update public.project_requests
  set status='quoted', updated_at=now()
  where id=v_quote.request_id;

  update public.project_workflows
  set current_stage='quote_sent', progress_percent=40,
      estimated_price_aed=v_quote.total_aed, updated_at=now()
  where request_id=v_quote.request_id;

  insert into public.project_request_events(request_id,user_id,status,note,note_ar)
  values (v_quote.request_id,v_quote.user_id,'quoted','EVENTO sent the project quotation for customer review.','أرسلت EVENTO عرض سعر المشروع لمراجعة العميل.');

  return jsonb_build_object('quote_id',v_quote.id,'status','sent','total_aed',v_quote.total_aed);
end;
$$;

create or replace function public.evento_accept_quote_v1(
  p_user_id uuid,
  p_quote_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_quote public.project_quotes%rowtype;
  v_is_anonymous boolean;
begin
  select is_anonymous into v_is_anonymous from auth.users where id=p_user_id;
  if v_is_anonymous is null then raise exception 'user_not_found'; end if;
  if v_is_anonymous then raise exception 'verified_account_required'; end if;

  select * into v_quote
  from public.project_quotes
  where id=p_quote_id
  for update;

  if v_quote.id is null then raise exception 'quote_not_found'; end if;
  if v_quote.user_id <> p_user_id then raise exception 'forbidden'; end if;
  if v_quote.status <> 'sent' then raise exception 'quote_not_acceptable'; end if;
  if v_quote.valid_until is not null and v_quote.valid_until < now() then
    update public.project_quotes set status='expired',updated_at=now() where id=p_quote_id;
    raise exception 'quote_expired';
  end if;

  update public.project_quotes
  set status='accepted', accepted_at=now(), updated_at=now()
  where id=p_quote_id;

  update public.project_requests
  set status='approved', updated_at=now()
  where id=v_quote.request_id;

  update public.project_workflows
  set current_stage='quote_approved', progress_percent=45,
      estimated_price_aed=v_quote.total_aed, updated_at=now()
  where request_id=v_quote.request_id;

  insert into public.project_request_events(request_id,user_id,status,note,note_ar)
  values (v_quote.request_id,v_quote.user_id,'approved','Customer accepted the EVENTO quotation. Payment is the next commercial gate.','وافق العميل على عرض سعر EVENTO. الدفع هو البوابة التجارية التالية.');

  insert into public.project_build_queue(request_id,user_id,quote_id,status)
  values (v_quote.request_id,v_quote.user_id,v_quote.id,'pending_payment')
  on conflict (request_id) do update set
    quote_id=excluded.quote_id,
    status=case when public.project_build_queue.status='cancelled' then 'pending_payment' else public.project_build_queue.status end,
    updated_at=now();

  return jsonb_build_object(
    'quote_id',v_quote.id,
    'status','accepted',
    'request_id',v_quote.request_id,
    'next_gate','payment',
    'build_queue_status','pending_payment'
  );
end;
$$;

revoke all on function public.evento_create_quote_draft_v1(uuid,uuid,text,text,text,jsonb,timestamptz) from public,anon,authenticated;
revoke all on function public.evento_send_quote_v1(uuid,uuid) from public,anon,authenticated;
revoke all on function public.evento_accept_quote_v1(uuid,uuid) from public,anon,authenticated;
grant execute on function public.evento_create_quote_draft_v1(uuid,uuid,text,text,text,jsonb,timestamptz) to service_role;
grant execute on function public.evento_send_quote_v1(uuid,uuid) to service_role;
grant execute on function public.evento_accept_quote_v1(uuid,uuid) to service_role;
