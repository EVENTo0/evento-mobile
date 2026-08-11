import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/evento_theme.dart';

class EventoControlPlanePage extends StatefulWidget {
  const EventoControlPlanePage({super.key});

  @override
  State<EventoControlPlanePage> createState() => _EventoControlPlanePageState();
}

class _EventoControlPlanePageState extends State<EventoControlPlanePage> {
  bool _arabic = true;
  bool _loading = true;
  String? _error;
  _ControlPlaneSnapshot _snapshot = const _ControlPlaneSnapshot.empty();

  bool get _signedIn => Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!_signedIn) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _arabic
            ? 'سجّل الدخول إلى حساب EVENTO لعرض البيانات الحية.'
            : 'Sign in to your EVENTO account to view live data.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final requests = (await client
              .from('project_requests')
              .select('id,status,created_at'))
          .cast<Map<String, dynamic>>();
      final analyses = (await client.from('request_analyses').select('request_id'))
          .cast<Map<String, dynamic>>();
      final workflows = (await client
              .from('project_workflows')
              .select('request_id,current_stage,progress_percent'))
          .cast<Map<String, dynamic>>();
      final events = (await client
              .from('project_request_events')
              .select('request_id,status,created_at'))
          .cast<Map<String, dynamic>>();

      final analyzed = requests.where((row) => row['status'] == 'analyzed').length;
      final awaitingScope =
          requests.where((row) => row['status'] == 'awaiting_scope').length;
      final activeWorkflows = workflows.where((row) {
        final stage = row['current_stage']?.toString();
        return stage != null && stage.isNotEmpty && stage != 'completed';
      }).length;

      if (!mounted) return;
      setState(() {
        _snapshot = _ControlPlaneSnapshot(
          requests: requests.length,
          analyzed: analyzed,
          awaitingScope: awaitingScope,
          workflows: workflows.length,
          activeWorkflows: activeWorkflows,
          events: events.length,
          analyses: analyses.length,
          refreshedAt: DateTime.now(),
        );
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_arabic ? 'EVENTO • مركز القيادة' : 'EVENTO • Control Plane'),
          actions: [
            IconButton(
              tooltip: _arabic ? 'English' : 'العربية',
              onPressed: () => setState(() => _arabic = !_arabic),
              icon: const Icon(Icons.translate),
            ),
            IconButton(
              tooltip: _arabic ? 'تحديث' : 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              _StatusHero(arabic: _arabic, signedIn: _signedIn),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.warning_amber_rounded,
                  title: _arabic ? 'تنبيه' : 'Notice',
                  text: _error!,
                  accent: EventoColors.gold,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                _arabic ? 'المؤشرات الحية' : 'Live indicators',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  _MetricCard(
                    label: _arabic ? 'طلبات المشاريع' : 'Project requests',
                    value: _snapshot.requests,
                    icon: Icons.inbox_outlined,
                  ),
                  _MetricCard(
                    label: _arabic ? 'تحليلات مكتملة' : 'Analyses complete',
                    value: _snapshot.analyses,
                    icon: Icons.psychology_outlined,
                  ),
                  _MetricCard(
                    label: _arabic ? 'بانتظار النطاق' : 'Awaiting scope',
                    value: _snapshot.awaitingScope,
                    icon: Icons.rule_folder_outlined,
                  ),
                  _MetricCard(
                    label: _arabic ? 'مسارات تنفيذ' : 'Workflows',
                    value: _snapshot.workflows,
                    icon: Icons.account_tree_outlined,
                  ),
                  _MetricCard(
                    label: _arabic ? 'مسارات نشطة' : 'Active workflows',
                    value: _snapshot.activeWorkflows,
                    icon: Icons.play_circle_outline,
                  ),
                  _MetricCard(
                    label: _arabic ? 'أحداث مسجلة' : 'Recorded events',
                    value: _snapshot.events,
                    icon: Icons.timeline_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.shield_outlined,
                title: _arabic ? 'حدود الإصدار الحالي' : 'Current release boundary',
                text: _arabic
                    ? 'هذه الشاشة تقرأ فقط البيانات التي تسمح بها سياسات Supabase للمستخدم المسجل. لوحة مالك الشركة الكاملة، الإيرادات، المدفوعات، الفريق، الوكلاء، Builds وDeployments ستضاف بطبقة صلاحيات إدارية منفصلة وآمنة.'
                    : 'This screen reads only the rows permitted by Supabase policies for the signed-in user. Company-owner metrics, revenue, payments, team, agents, builds and deployments will use a separate secure admin authorization layer.',
                accent: EventoColors.cyan,
              ),
              if (_snapshot.refreshedAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${_arabic ? 'آخر تحديث' : 'Last refresh'}: ${_snapshot.refreshedAt!.toLocal()}',
                  style: const TextStyle(color: EventoColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.arabic, required this.signedIn});

  final bool arabic;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2741), Color(0xFF0A1626)],
        ),
        border: Border.all(color: const Color(0xFF1C4465)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                signedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: signedIn ? Colors.greenAccent : EventoColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                signedIn ? 'LIVE • SUPABASE' : 'AUTH REQUIRED',
                style: TextStyle(
                  color: signedIn ? Colors.greenAccent : EventoColors.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            arabic ? 'لوحة تشغيل EVENTO من الهاتف' : 'EVENTO operations from your phone',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            arabic
                ? 'نقطة البداية لمراقبة الطلبات، التنفيذ، العملاء، الإيرادات، الذكاء الاصطناعي والبنية التشغيلية من شاشة واحدة.'
                : 'The foundation for monitoring requests, delivery, customers, revenue, AI and infrastructure from one screen.',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: EventoColors.cyan),
            Text(
              '$value',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label, style: const TextStyle(color: EventoColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EventoColors.panelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPlaneSnapshot {
  const _ControlPlaneSnapshot({
    required this.requests,
    required this.analyzed,
    required this.awaitingScope,
    required this.workflows,
    required this.activeWorkflows,
    required this.events,
    required this.analyses,
    required this.refreshedAt,
  });

  const _ControlPlaneSnapshot.empty()
      : requests = 0,
        analyzed = 0,
        awaitingScope = 0,
        workflows = 0,
        activeWorkflows = 0,
        events = 0,
        analyses = 0,
        refreshedAt = null;

  final int requests;
  final int analyzed;
  final int awaitingScope;
  final int workflows;
  final int activeWorkflows;
  final int events;
  final int analyses;
  final DateTime? refreshedAt;
}
