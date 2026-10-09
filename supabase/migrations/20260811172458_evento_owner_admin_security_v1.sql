create schema if not exists private;

create table if not exists private.evento_company_memberships (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','ops','finance','marketing','developer')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table private.evento_company_memberships enable row level security;
revoke all on private.evento_company_memberships from public, anon, authenticated;

insert into private.evento_company_memberships (user_id, role, active)
select id, 'owner', true
from auth.users
where is_anonymous is false
order by created_at asc
limit 1
on conflict (user_id) do update
set role = 'owner', active = true, updated_at = now();

create or replace function private.evento_staff_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select m.role
  from private.evento_company_memberships m
  where m.user_id = (select auth.uid())
    and m.active = true
  limit 1
$$;

create or replace function private.is_evento_staff()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from private.evento_company_memberships m
    where m.user_id = (select auth.uid())
      and m.active = true
      and m.role in ('owner','admin','ops')
  )
$$;

revoke all on function private.evento_staff_role() from public, anon;
revoke all on function private.is_evento_staff() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.evento_staff_role() to authenticated;
grant execute on function private.is_evento_staff() to authenticated;

drop policy if exists evento_staff_select_all on public.project_requests;
create policy evento_staff_select_all
on public.project_requests
for select
to authenticated
using ((select private.is_evento_staff()));

drop policy if exists evento_staff_select_all on public.request_analyses;
create policy evento_staff_select_all
on public.request_analyses
for select
to authenticated
using ((select private.is_evento_staff()));

drop policy if exists evento_staff_select_all on public.project_workflows;
create policy evento_staff_select_all
on public.project_workflows
for select
to authenticated
using ((select private.is_evento_staff()));

drop policy if exists evento_staff_select_all on public.project_request_events;
create policy evento_staff_select_all
on public.project_request_events
for select
to authenticated
using ((select private.is_evento_staff()));

create or replace function public.start_project_workflow(p_request_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_status text;
  v_is_anonymous boolean;
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  v_is_anonymous := coalesce((auth.jwt()->>'is_anonymous')::boolean, true);
  if v_is_anonymous then raise exception 'verified_account_required'; end if;

  select user_id, status into v_user_id, v_status
  from public.project_requests
  where id = p_request_id
  for update;

  if v_user_id is null then raise exception 'request_not_found'; end if;
  if v_user_id <> auth.uid() then raise exception 'forbidden'; end if;
  if v_status not in ('analyzed','awaiting_scope') then raise exception 'workflow_not_startable'; end if;

  insert into public.project_workflows(request_id,user_id,current_stage,progress_percent)
  values (p_request_id,v_user_id,'scope_review',20)
  on conflict (request_id) do update set
    current_stage = case when public.project_workflows.current_stage = 'analysis_complete' then 'scope_review' else public.project_workflows.current_stage end,
    progress_percent = greatest(public.project_workflows.progress_percent,20),
    updated_at = now();

  update public.project_requests set status='awaiting_scope' where id=p_request_id;

  if not exists (
    select 1 from public.project_request_events
    where request_id=p_request_id and status='awaiting_scope'
  ) then
    insert into public.project_request_events(request_id,user_id,status,note,note_ar)
    values (p_request_id,v_user_id,'awaiting_scope','Project scope is ready for customer review.','نطاق المشروع جاهز لمراجعة العميل.');
  end if;

  return 'scope_review';
end;
$$;

create or replace function public.approve_project_scope(p_request_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_status text;
  v_is_anonymous boolean;
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  v_is_anonymous := coalesce((auth.jwt()->>'is_anonymous')::boolean, true);
  if v_is_anonymous then raise exception 'verified_account_required'; end if;

  select user_id,status::text into v_user_id,v_status
  from public.project_requests
  where id=p_request_id
  for update;

  if v_user_id is null then raise exception 'request_not_found'; end if;
  if v_user_id <> auth.uid() then raise exception 'forbidden'; end if;
  if v_status <> 'awaiting_scope' then raise exception 'scope_not_approvable'; end if;

  update public.project_workflows
  set current_stage='scope_approved', progress_percent=30,
      scope_approved_at=coalesce(scope_approved_at,now()), updated_at=now()
  where request_id=p_request_id and user_id=v_user_id;

  if not found then raise exception 'workflow_not_found'; end if;

  insert into public.project_request_events(request_id,user_id,status,note,note_ar)
  values (p_request_id,v_user_id,'approved','Customer approved the proposed project scope.','وافق العميل على نطاق المشروع المقترح.');

  return 'scope_approved';
end;
$$;

revoke all on function public.start_project_workflow(uuid) from public, anon;
revoke all on function public.approve_project_scope(uuid) from public, anon;
grant execute on function public.start_project_workflow(uuid) to authenticated;
grant execute on function public.approve_project_scope(uuid) to authenticated;

revoke all on function public.finalize_request_analysis_v2(uuid,text,text,text,jsonb,jsonb,jsonb,jsonb,text) from public, anon, authenticated;
grant execute on function public.finalize_request_analysis_v2(uuid,text,text,text,jsonb,jsonb,jsonb,jsonb,text) to service_role;
