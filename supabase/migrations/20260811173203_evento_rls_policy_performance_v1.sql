drop policy if exists evento_staff_select_all on public.project_requests;
drop policy if exists project_requests_select_own on public.project_requests;
create policy project_requests_select_access
on public.project_requests
for select
to authenticated
using (
  ((select auth.uid()) is not null)
  and (
    (select auth.uid()) = user_id
    or (select private.is_evento_staff())
  )
);

drop policy if exists evento_staff_select_all on public.request_analyses;
drop policy if exists request_analyses_select_own on public.request_analyses;
create policy request_analyses_select_access
on public.request_analyses
for select
to authenticated
using (
  ((select auth.uid()) is not null)
  and (
    (select auth.uid()) = user_id
    or (select private.is_evento_staff())
  )
);

drop policy if exists evento_staff_select_all on public.project_workflows;
drop policy if exists project_workflows_select_own on public.project_workflows;
create policy project_workflows_select_access
on public.project_workflows
for select
to authenticated
using (
  ((select auth.uid()) is not null)
  and (
    (select auth.uid()) = user_id
    or (select private.is_evento_staff())
  )
);

drop policy if exists evento_staff_select_all on public.project_request_events;
drop policy if exists project_request_events_select_own on public.project_request_events;
create policy project_request_events_select_access
on public.project_request_events
for select
to authenticated
using (
  ((select auth.uid()) is not null)
  and (
    (select auth.uid()) = user_id
    or (select private.is_evento_staff())
  )
);

create index if not exists project_workflows_request_user_idx
  on public.project_workflows (request_id, user_id);
create index if not exists project_workflows_user_id_idx
  on public.project_workflows (user_id);
