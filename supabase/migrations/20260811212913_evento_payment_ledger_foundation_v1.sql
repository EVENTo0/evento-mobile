create table if not exists public.project_payments (
  id uuid primary key default gen_random_uuid(),
  payment_code text not null unique default ((('EVP-'::text || to_char(now(), 'YYMMDD'::text)) || '-'::text) || upper(substr(replace((gen_random_uuid())::text, '-'::text, ''::text), 1, 6))),
  request_id uuid not null references public.project_requests(id) on delete cascade,
  quote_id uuid not null references public.project_quotes(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'stripe' check (provider in ('stripe','tap','manual')),
  provider_checkout_session_id text unique,
  provider_payment_intent_id text unique,
  currency text not null default 'AED' check (currency='AED'),
  amount_aed numeric(12,2) not null check (amount_aed > 0),
  status text not null default 'pending' check (status in ('pending','checkout_created','paid','failed','cancelled','refunded','partially_refunded')),
  checkout_url text,
  paid_at timestamptz,
  refunded_aed numeric(12,2) not null default 0 check (refunded_aed >= 0),
  last_provider_event_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (quote_id, provider)
);

create index if not exists project_payments_user_created_idx on public.project_payments(user_id,created_at desc);
create index if not exists project_payments_status_idx on public.project_payments(status);
create index if not exists project_payments_request_idx on public.project_payments(request_id);

alter table public.project_payments enable row level security;
create policy project_payments_select_access on public.project_payments for select to authenticated
using (((select auth.uid()) is not null)
  and coalesce((select (auth.jwt()->>'is_anonymous')::boolean), true) = false
  and ((select auth.uid()) = user_id or (select private.is_evento_staff())));
revoke all on public.project_payments from anon, authenticated;
grant select on public.project_payments to authenticated;
grant all on public.project_payments to service_role;

create or replace function public.evento_prepare_payment_v1(p_user_id uuid,p_quote_id uuid,p_provider text default 'stripe')
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_quote public.project_quotes%rowtype; v_payment public.project_payments%rowtype; v_is_anonymous boolean;
begin
  select is_anonymous into v_is_anonymous from auth.users where id=p_user_id;
  if v_is_anonymous is null then raise exception 'user_not_found'; end if;
  if v_is_anonymous then raise exception 'verified_account_required'; end if;
  select * into v_quote from public.project_quotes where id=p_quote_id for update;
  if v_quote.id is null then raise exception 'quote_not_found'; end if;
  if v_quote.user_id <> p_user_id then raise exception 'forbidden'; end if;
  if v_quote.status <> 'accepted' then raise exception 'quote_not_accepted'; end if;
  if p_provider not in ('stripe','tap') then raise exception 'provider_not_supported'; end if;
  insert into public.project_payments(request_id,quote_id,user_id,provider,currency,amount_aed,status)
  values(v_quote.request_id,v_quote.id,p_user_id,p_provider,'AED',v_quote.total_aed,'pending')
  on conflict (quote_id,provider) do update set updated_at=now() returning * into v_payment;
  return jsonb_build_object('payment_id',v_payment.id,'payment_code',v_payment.payment_code,'request_id',v_payment.request_id,'quote_id',v_payment.quote_id,'amount_aed',v_payment.amount_aed,'currency',v_payment.currency,'status',v_payment.status,'provider',v_payment.provider);
end; $$;
revoke all on function public.evento_prepare_payment_v1(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.evento_prepare_payment_v1(uuid,uuid,text) to service_role;

create or replace function public.evento_record_checkout_session_v1(p_payment_id uuid,p_checkout_session_id text,p_checkout_url text)
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.project_payments set provider_checkout_session_id=p_checkout_session_id,checkout_url=p_checkout_url,status='checkout_created',updated_at=now()
  where id=p_payment_id and status in ('pending','checkout_created');
  if not found then raise exception 'payment_not_checkout_ready'; end if;
end; $$;
revoke all on function public.evento_record_checkout_session_v1(uuid,text,text) from public,anon,authenticated;
grant execute on function public.evento_record_checkout_session_v1(uuid,text,text) to service_role;

create or replace function public.evento_mark_payment_paid_v1(p_checkout_session_id text,p_payment_intent_id text,p_provider_event_id text,p_amount_aed numeric,p_currency text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_payment public.project_payments%rowtype;
begin
  select * into v_payment from public.project_payments where provider_checkout_session_id=p_checkout_session_id for update;
  if v_payment.id is null then raise exception 'payment_not_found'; end if;
  if lower(p_currency) <> 'aed' then raise exception 'currency_mismatch'; end if;
  if round(v_payment.amount_aed,2) <> round(p_amount_aed,2) then raise exception 'amount_mismatch'; end if;
  if v_payment.status='paid' then return jsonb_build_object('payment_id',v_payment.id,'status','paid','idempotent',true); end if;
  if v_payment.status not in ('pending','checkout_created') then raise exception 'payment_not_payable'; end if;
  update public.project_payments set provider_payment_intent_id=coalesce(p_payment_intent_id,provider_payment_intent_id),status='paid',paid_at=coalesce(paid_at,now()),last_provider_event_id=p_provider_event_id,updated_at=now() where id=v_payment.id;
  update public.project_build_queue set status='queued',enqueued_at=coalesce(enqueued_at,now()),updated_at=now() where quote_id=v_payment.quote_id and status='pending_payment';
  update public.project_workflows set current_stage='build_queue',progress_percent=60,updated_at=now() where request_id=v_payment.request_id;
  insert into public.project_request_events(request_id,user_id,status,note,note_ar) values(v_payment.request_id,v_payment.user_id,'paid','Payment confirmed by provider; project entered Build Queue.','تم تأكيد الدفع من مزود الدفع ونقل المشروع إلى قائمة انتظار البناء.');
  return jsonb_build_object('payment_id',v_payment.id,'status','paid','request_id',v_payment.request_id);
end; $$;
revoke all on function public.evento_mark_payment_paid_v1(text,text,text,numeric,text) from public,anon,authenticated;
grant execute on function public.evento_mark_payment_paid_v1(text,text,text,numeric,text) to service_role;
