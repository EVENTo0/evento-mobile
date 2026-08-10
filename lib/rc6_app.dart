import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/evento_theme.dart';
import 'data/repositories/project_request_repository.dart';
import 'domain/project_request.dart';
import 'domain/project_workflow.dart';
import 'rc5_app.dart';

class EventoRc6App extends StatelessWidget {
  const EventoRc6App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EVENTO RC6',
      theme: buildEventoTheme(),
      home: const _Rc6Host(),
    );
  }
}

class _Rc6Host extends StatelessWidget {
  const _Rc6Host();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const EventoRc5App(),
          Positioned(
            right: 16,
            bottom: 92,
            child: FloatingActionButton.extended(
              heroTag: 'rc6-workflow',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const _WorkflowCenterPage()),
              ),
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Workflow'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowCenterPage extends StatefulWidget {
  const _WorkflowCenterPage();

  @override
  State<_WorkflowCenterPage> createState() => _WorkflowCenterPageState();
}

class _WorkflowCenterPageState extends State<_WorkflowCenterPage> {
  bool arabic = true;
  bool busy = false;
  String? message;
  List<ProjectRequestRecord> requests = const <ProjectRequestRecord>[];
  final Map<String, ProjectWorkflowRecord?> workflows = <String, ProjectWorkflowRecord?>{};

  SupabaseProjectRequestRepository get repository =>
      SupabaseProjectRequestRepository(Supabase.instance.client);

  bool get signedIn => Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!signedIn) {
      if (mounted) {
        setState(() => message = arabic
            ? 'سجّل الدخول من حساب EVENTO أولًا.'
            : 'Sign in from the EVENTO Account screen first.');
      }
      return;
    }

    setState(() {
      busy = true;
      message = null;
    });
    try {
      final List<ProjectRequestRecord> rows = await repository.listMine();
      final Map<String, ProjectWorkflowRecord?> next = <String, ProjectWorkflowRecord?>{};
      for (final ProjectRequestRecord row in rows) {
        next[row.id] = await repository.getWorkflow(row.id);
      }
      if (!mounted) return;
      setState(() {
        requests = rows;
        workflows
          ..clear()
          ..addAll(next);
      });
    } catch (error) {
      if (mounted) setState(() => message = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _start(ProjectRequestRecord request) async {
    await _runTransition(
      () => repository.startWorkflow(request.id),
      arabic ? 'تم فتح مراجعة النطاق.' : 'Scope review started.',
    );
  }

  Future<void> _approve(ProjectRequestRecord request) async {
    await _runTransition(
      () => repository.approveScope(request.id),
      arabic ? 'تم اعتماد نطاق المشروع.' : 'Project scope approved.',
    );
  }

  Future<void> _runTransition(Future<void> Function() action, String success) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
      await _load();
      if (mounted) setState(() => message = success);
    } catch (error) {
      if (mounted) setState(() => message = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(arabic ? 'مركز تنفيذ المشاريع • RC6' : 'Project Workflow Center • RC6'),
          actions: <Widget>[
            IconButton(
              onPressed: () => setState(() => arabic = !arabic),
              icon: const Icon(Icons.translate),
            ),
            IconButton(onPressed: busy ? null : _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: <Widget>[
              _WorkflowIntro(arabic: arabic),
              if (message != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(message!, style: const TextStyle(color: EventoColors.gold)),
              ],
              const SizedBox(height: 18),
              if (busy) const LinearProgressIndicator(),
              if (!signedIn)
                _WorkflowInfo(
                  title: arabic ? 'تسجيل الدخول مطلوب' : 'Sign-in required',
                  text: arabic
                      ? 'ارجع إلى حسابي وسجّل دخول Live Beta ثم افتح Workflow.'
                      : 'Return to Account, sign into Live Beta, then reopen Workflow.',
                )
              else if (requests.isEmpty)
                _WorkflowInfo(
                  title: arabic ? 'لا توجد طلبات' : 'No requests',
                  text: arabic ? 'أنشئ طلب مشروع أولًا.' : 'Create a project request first.',
                )
              else
                for (final ProjectRequestRecord request in requests)
                  _WorkflowRequestCard(
                    arabic: arabic,
                    request: request,
                    workflow: workflows[request.id],
                    busy: busy,
                    onStart: () => _start(request),
                    onApprove: () => _approve(request),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowIntro extends StatelessWidget {
  const _WorkflowIntro({required this.arabic});

  final bool arabic;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(Icons.verified_user_outlined, color: EventoColors.cyan),
                  SizedBox(width: 8),
                  Text('SERVER-CONTROLLED', style: TextStyle(color: EventoColors.cyan, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                arabic
                    ? 'ينقل RC6 المشروع من التحليل إلى النطاق ثم الاعتماد. المراحل اللاحقة لا يستطيع العميل القفز إليها مباشرة.'
                    : 'RC6 moves a project from analysis to scope review and approval. Later production stages cannot be skipped by the customer.',
              ),
            ],
          ),
        ),
      );
}

class _WorkflowRequestCard extends StatelessWidget {
  const _WorkflowRequestCard({
    required this.arabic,
    required this.request,
    required this.workflow,
    required this.busy,
    required this.onStart,
    required this.onApprove,
  });

  final bool arabic;
  final ProjectRequestRecord request;
  final ProjectWorkflowRecord? workflow;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final ProjectWorkflowRecord? flow = workflow;
    final String requestStatus = request.status.name;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(request.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 4),
            Text(request.requestCode, style: const TextStyle(color: EventoColors.muted)),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (flow?.progressPercent ?? 15) / 100),
            const SizedBox(height: 8),
            Text(
              flow == null
                  ? (arabic ? 'اكتمل التحليل • جاهز لبدء Workflow' : 'Analysis complete • ready to start workflow')
                  : '${flow.localizedStage(arabic)} • ${flow.progressPercent}%',
              style: const TextStyle(color: EventoColors.cyan, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (flow == null && requestStatus == 'analyzed')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(arabic ? 'ابدأ مراجعة نطاق المشروع' : 'Start scope review'),
                ),
              )
            else if (flow?.currentStage == 'scope_review' || requestStatus == 'awaiting_scope')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  icon: const Icon(Icons.approval_outlined),
                  label: Text(arabic ? 'اعتمد نطاق المشروع' : 'Approve project scope'),
                ),
              )
            else if (flow?.currentStage == 'scope_approved')
              _WorkflowInfo(
                title: arabic ? 'النطاق معتمد' : 'Scope approved',
                text: arabic
                    ? 'الخطوة التالية Server-side: إعداد عرض السعر والموافقة قبل Build Queue.'
                    : 'Next server-side step: quote preparation and approval before Build Queue.',
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowInfo extends StatelessWidget {
  const _WorkflowInfo({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EventoColors.cyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.info_outline, color: EventoColors.cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      );
}
