drop policy if exists project_quotes_select_access on public.project_quotes;
create policy project_quotes_select_access
on public.project_quotes
for select
to authenticated
using (
  ((select auth.uid()) is not null)
  and coalesce((select (auth.jwt()->>'is_anonymous')::boolean), true) = false
  and (
    (select auth.uid()) = user_id
    or (select private.is_evento_staff())
  )
);

drop policy if exists project_build_queue_select_access on public.project_build_queue;
create policy project_build_queue_select_access
on public.project_build_queue
for select
to authenticated
using (
  ((select auth.uid()) is not null)
  and coalesce((select (auth.jwt()->>'is_anonymous')::boolean), true) = false
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
  v_customer_is_anonymous boolean;
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

  select r.user_id, u.is_anonymous, w.current_stage
  into v_request_user_id, v_customer_is_anonymous, v_stage
  from public.project_requests r
  join auth.users u on u.id=r.user_id
  join public.project_workflows w on w.request_id=r.id
  where r.id=p_request_id
  for update of r,w;

  if v_request_user_id is null then raise exception 'request_not_found'; end if;
  if coalesce(v_customer_is_anonymous,true) then raise exception 'verified_customer_required'; end if;
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

revoke all on function public.evento_create_quote_draft_v1(uuid,uuid,text,text,text,jsonb,timestamptz) from public,anon,authenticated;
grant execute on function public.evento_create_quote_draft_v1(uuid,uuid,text,text,text,jsonb,timestamptz) to service_role;
