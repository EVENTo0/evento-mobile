create or replace function public.evento_transition_project_workflow_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_action text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request_user_id uuid;
  v_status text;
  v_is_anonymous boolean;
  v_stage text;
  v_progress integer;
begin
  select u.is_anonymous into v_is_anonymous
  from auth.users u
  where u.id = p_user_id;

  if v_is_anonymous is null then raise exception 'user_not_found'; end if;
  if v_is_anonymous then raise exception 'verified_account_required'; end if;

  select user_id, status::text into v_request_user_id, v_status
  from public.project_requests
  where id = p_request_id
  for update;

  if v_request_user_id is null then raise exception 'request_not_found'; end if;
  if v_request_user_id <> p_user_id then raise exception 'forbidden'; end if;

  if p_action = 'start' then
    if v_status not in ('analyzed','awaiting_scope') then raise exception 'workflow_not_startable'; end if;

    insert into public.project_workflows(request_id,user_id,current_stage,progress_percent)
    values (p_request_id,p_user_id,'scope_review',20)
    on conflict (request_id) do update set
      current_stage = case
        when public.project_workflows.current_stage = 'analysis_complete' then 'scope_review'
        else public.project_workflows.current_stage
      end,
      progress_percent = greatest(public.project_workflows.progress_percent,20),
      updated_at = now();

    update public.project_requests
    set status='awaiting_scope', updated_at=now()
    where id=p_request_id;

    if not exists (
      select 1 from public.project_request_events
      where request_id=p_request_id and status='awaiting_scope'
    ) then
      insert into public.project_request_events(request_id,user_id,status,note,note_ar)
      values (p_request_id,p_user_id,'awaiting_scope','Project scope is ready for customer review.','نطاق المشروع جاهز لمراجعة العميل.');
    end if;

    v_stage := 'scope_review';
    v_progress := 20;

  elsif p_action = 'approve' then
    if v_status <> 'awaiting_scope' then raise exception 'scope_not_approvable'; end if;

    update public.project_workflows
    set current_stage='scope_approved',
        progress_percent=30,
        scope_approved_at=coalesce(scope_approved_at,now()),
        updated_at=now()
    where request_id=p_request_id and user_id=p_user_id;

    if not found then raise exception 'workflow_not_found'; end if;

    insert into public.project_request_events(request_id,user_id,status,note,note_ar)
    values (p_request_id,p_user_id,'approved','Customer approved the proposed project scope.','وافق العميل على نطاق المشروع المقترح.');

    v_stage := 'scope_approved';
    v_progress := 30;
  else
    raise exception 'invalid_action';
  end if;

  return jsonb_build_object(
    'request_id', p_request_id,
    'stage', v_stage,
    'progress_percent', v_progress
  );
end;
$$;

revoke all on function public.evento_transition_project_workflow_v1(uuid,uuid,text) from public, anon, authenticated;
grant execute on function public.evento_transition_project_workflow_v1(uuid,uuid,text) to service_role;
