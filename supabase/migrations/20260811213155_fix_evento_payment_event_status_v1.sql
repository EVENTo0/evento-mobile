create or replace function public.evento_mark_payment_paid_v1(
  p_checkout_session_id text,
  p_payment_intent_id text,
  p_provider_event_id text,
  p_amount_aed numeric,
  p_currency text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_payment public.project_payments%rowtype;
begin
  select * into v_payment from public.project_payments where provider_checkout_session_id=p_checkout_session_id for update;
  if v_payment.id is null then raise exception 'payment_not_found'; end if;
  if lower(p_currency) <> 'aed' then raise exception 'currency_mismatch'; end if;
  if round(v_payment.amount_aed,2) <> round(p_amount_aed,2) then raise exception 'amount_mismatch'; end if;
  if v_payment.status='paid' then return jsonb_build_object('payment_id',v_payment.id,'status','paid','idempotent',true); end if;
  if v_payment.status not in ('pending','checkout_created') then raise exception 'payment_not_payable'; end if;
  update public.project_payments set provider_payment_intent_id=coalesce(p_payment_intent_id,provider_payment_intent_id),status='paid',paid_at=coalesce(paid_at,now()),last_provider_event_id=p_provider_event_id,updated_at=now() where id=v_payment.id;
  update public.project_build_queue set status='queued',queued_at=coalesce(queued_at,now()),updated_at=now() where quote_id=v_payment.quote_id and status='pending_payment';
  update public.project_workflows set current_stage='build_queue',progress_percent=60,updated_at=now() where request_id=v_payment.request_id;
  insert into public.project_request_events(request_id,user_id,status,note,note_ar) values(v_payment.request_id,v_payment.user_id,'approved','Payment confirmed by provider; project entered Build Queue.','تم تأكيد الدفع من مزود الدفع ونقل المشروع إلى قائمة انتظار البناء.');
  return jsonb_build_object('payment_id',v_payment.id,'status','paid','request_id',v_payment.request_id);
end;
$$;
revoke all on function public.evento_mark_payment_paid_v1(text,text,text,numeric,text) from public,anon,authenticated;
grant execute on function public.evento_mark_payment_paid_v1(text,text,text,numeric,text) to service_role;
