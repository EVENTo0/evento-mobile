import 'package:flutter/material.dart';

import '../core/evento_strings.dart';
import '../core/evento_theme.dart';
import '../data/demo_analysis.dart';
import '../data/mock_data.dart';
import '../data/portfolio_catalog.dart';
import '../domain/portfolio_project.dart';
import '../domain/project_request.dart';

typedef ProjectRequestOpener = void Function([PortfolioProject? project]);
typedef LiveRequestSubmitter = Future<ProjectRequestRecord> Function(DemoOrder order);

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.s,
    required this.onRequestTap,
    required this.onProjectsTap,
    required this.onProjectRequest,
  });

  final EventoStrings s;
  final ProjectRequestOpener onRequestTap;
  final VoidCallback onProjectsTap;
  final ProjectRequestOpener onProjectRequest;

  @override
  Widget build(BuildContext context) {
    final List<PortfolioProject> featured = portfolioProjects
        .where((PortfolioProject p) => p.status == 'active' || p.status == 'under-development')
        .take(5)
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF113657), Color(0xFF071524)],
            ),
            border: Border.all(color: const Color(0xFF1B486C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _StatusPill(icon: Icons.auto_awesome, label: 'EVENTO LIVE BETA'),
              const SizedBox(height: 18),
              Text(
                s.tagline,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                s.arabic
                    ? 'اكتشف مشاريع EVENTO، حلّل فكرتك، أنشئ طلبك، وتابع التنفيذ من هاتفك.'
                    : 'Discover EVENTO projects, analyze your idea, create a request, and track delivery from your phone.',
                style: const TextStyle(color: EventoColors.muted, height: 1.55),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => onRequestTap(),
                icon: const Icon(Icons.bolt_rounded),
                label: Text(s.startProject),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onProjectsTap,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(s.browseProjects),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: s.featured, trailing: '${portfolioProjects.length}'),
        const SizedBox(height: 12),
        SizedBox(
          height: 212,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final PortfolioProject project = featured[index];
              return SizedBox(
                width: 260,
                child: _ProjectCard(
                  project: project,
                  arabic: s.arabic,
                  onRequest: () => onProjectRequest(project),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: s.howItWorks),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _ProcessTile(icon: Icons.lightbulb_outline_rounded, number: '01', ar: 'الفكرة', en: 'Idea'),
            _ProcessTile(icon: Icons.psychology_alt_outlined, number: '02', ar: 'التحليل', en: 'Analysis'),
            _ProcessTile(icon: Icons.architecture_outlined, number: '03', ar: 'النطاق', en: 'Scope'),
            _ProcessTile(icon: Icons.phone_android_rounded, number: '04', ar: 'التجربة', en: 'Test'),
          ],
        ),
      ],
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, required this.s, required this.onRequestTap});

  final EventoStrings s;
  final ProjectRequestOpener onRequestTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: <Widget>[
        _SectionHeader(title: s.serviceTitle),
        const SizedBox(height: 8),
        Text(
          s.arabic
              ? 'اختر نقطة البداية، وسنحوّلها إلى متطلبات ونطاق قابل للبناء والاختبار.'
              : 'Choose a starting point and EVENTO will turn it into buildable, testable requirements and scope.',
          style: const TextStyle(color: EventoColors.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        ...services.map(
          (ServiceItem item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: EventoColors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: EventoColors.cyan),
                ),
                title: Text(s.arabic ? item.ar : item.en, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(s.arabic ? item.detailAr : item.detailEn),
                ),
                trailing: IconButton(
                  tooltip: s.startProject,
                  onPressed: () => onRequestTap(),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, required this.s, required this.onRequestProject});

  final EventoStrings s;
  final ProjectRequestOpener onRequestProject;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String query = '';
  String category = 'all';
  String status = 'all';

  @override
  Widget build(BuildContext context) {
    final List<String> categories = <String>{
      'all',
      ...portfolioProjects.map((PortfolioProject p) => p.category),
    }.toList()..sort();
    final List<String> statuses = <String>{
      'all',
      ...portfolioProjects.map((PortfolioProject p) => p.status),
    }.toList()..sort();
    final List<PortfolioProject> filtered = portfolioProjects.where((PortfolioProject project) {
      return project.matches(query) &&
          (category == 'all' || project.category == category) &&
          (status == 'all' || project.status == status);
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: <Widget>[
        _SectionHeader(title: widget.s.projectCatalog, trailing: '${filtered.length}/${portfolioProjects.length}'),
        const SizedBox(height: 12),
        TextField(
          onChanged: (String value) => setState(() => query = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: widget.s.arabic ? 'ابحث بالاسم أو المجال أو الحالة' : 'Search name, category, or status',
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              DropdownButton<String>(
                value: category,
                items: categories
                    .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value == 'all' ? (widget.s.arabic ? 'كل المجالات' : 'All categories') : value)))
                    .toList(),
                onChanged: (String? value) => setState(() => category = value ?? 'all'),
              ),
              const SizedBox(width: 18),
              DropdownButton<String>(
                value: status,
                items: statuses
                    .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value == 'all' ? (widget.s.arabic ? 'كل الحالات' : 'All statuses') : value)))
                    .toList(),
                onChanged: (String? value) => setState(() => status = value ?? 'all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          _EmptyState(
            icon: Icons.search_off_rounded,
            text: widget.s.arabic ? 'لا توجد مشاريع مطابقة.' : 'No matching projects.',
          )
        else
          ...filtered.map(
            (PortfolioProject project) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProjectCard(
                project: project,
                arabic: widget.s.arabic,
                onRequest: () => widget.onRequestProject(project),
              ),
            ),
          ),
      ],
    );
  }
}

class RequestScreen extends StatefulWidget {
  const RequestScreen({
    super.key,
    required this.s,
    required this.seedProject,
    required this.seedRevision,
    required this.onOrderCreated,
    required this.onOpenAccount,
    required this.backendConfigured,
    required this.backendSignedIn,
    required this.onLiveSubmit,
  });

  final EventoStrings s;
  final PortfolioProject? seedProject;
  final int seedRevision;
  final ValueChanged<DemoOrder> onOrderCreated;
  final VoidCallback onOpenAccount;
  final bool backendConfigured;
  final bool backendSignedIn;
  final LiveRequestSubmitter? onLiveSubmit;

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  String type = 'Mobile App';
  bool busy = false;
  DemoOrder? result;
  ProjectRequestRecord? liveResult;
  String? errorText;

  @override
  void didUpdateWidget(covariant RequestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seedRevision != widget.seedRevision && widget.seedProject != null) {
      final PortfolioProject project = widget.seedProject!;
      titleController.text = widget.s.arabic ? 'مشروع مستوحى من ${project.nameAr}' : 'Project inspired by ${project.name}';
      detailsController.text = widget.s.arabic
          ? 'أريد تطوير مشروع مشابه لـ ${project.nameAr} مع تخصيصه لاحتياجي. المرجع: ${project.summaryAr}'
          : 'I want to develop a project inspired by ${project.name}, customized to my needs. Reference: ${project.summaryEn}';
      setState(() {
        result = null;
        liveResult = null;
        errorText = null;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      errorText = null;
      liveResult = null;
    });
    final DemoOrder order = createDemoOrder(
      type: type,
      title: titleController.text,
      details: detailsController.text,
      sourceProjectId: widget.seedProject?.id,
    );
    try {
      final LiveRequestSubmitter? liveSubmit = widget.onLiveSubmit;
      if (liveSubmit != null) {
        final ProjectRequestRecord serverOrder = await liveSubmit(order);
        if (!mounted) return;
        setState(() {
          result = order;
          liveResult = serverOrder;
        });
      } else {
        widget.onOrderCreated(order);
        if (!mounted) return;
        setState(() => result = order);
      }
    } catch (error) {
      widget.onOrderCreated(order);
      if (!mounted) return;
      setState(() {
        result = order;
        errorText = widget.s.arabic
            ? 'تم الاحتفاظ بالتحليل محليًا لأن الحفظ الحي تعذر: $error'
            : 'The analysis was kept locally because the live save failed: $error';
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool liveReady = widget.backendConfigured && widget.backendSignedIn;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: <Widget>[
        _SectionHeader(title: widget.s.requestTitle),
        const SizedBox(height: 8),
        _StatusPill(
          icon: liveReady ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
          label: liveReady
              ? (widget.s.arabic ? 'LIVE — سيُحفظ الطلب في EVENTO' : 'LIVE — request will be saved to EVENTO')
              : (widget.s.arabic ? 'DEMO SAFE — التحليل يعمل محليًا' : 'DEMO SAFE — analysis runs locally'),
        ),
        const SizedBox(height: 14),
        Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(labelText: widget.s.arabic ? 'نوع المشروع' : 'Project type'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'Mobile App', child: Text('Mobile App')),
                  DropdownMenuItem(value: 'Website', child: Text('Website / Platform')),
                  DropdownMenuItem(value: 'AI', child: Text('AI Solution')),
                  DropdownMenuItem(value: 'Game', child: Text('Game / XR')),
                ],
                onChanged: (String? value) => setState(() => type = value ?? type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: widget.s.arabic ? 'اسم أو عنوان الفكرة' : 'Idea title'),
                validator: (String? value) => (value?.trim().length ?? 0) < 4
                    ? (widget.s.arabic ? 'اكتب عنوانًا أوضح.' : 'Enter a clearer title.')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: detailsController,
                minLines: 6,
                maxLines: 12,
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: widget.s.arabic ? 'اشرح ما تريد أن يبنيه EVENTO' : 'Describe what EVENTO should build',
                  hintText: widget.s.arabic
                      ? 'مثال: تطبيق مع تسجيل دخول، دفع، إشعارات، لوحة إدارة وتحليل AI...'
                      : 'Example: app with login, payments, notifications, admin dashboard and AI analysis...',
                ),
                validator: (String? value) => (value?.trim().length ?? 0) < 25
                    ? (widget.s.arabic ? 'أضف تفاصيل أكثر حتى يكون التحليل مفيدًا.' : 'Add more detail so the analysis is useful.')
                    : null,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : submit,
                  icon: busy
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.psychology_alt_rounded),
                  label: Text(widget.s.arabic ? 'حلّل وأنشئ الطلب' : 'Analyze & create request'),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(errorText!, style: const TextStyle(color: EventoColors.gold)),
        ],
        if (result != null) ...<Widget>[
          const SizedBox(height: 22),
          _AnalysisCard(order: result!, live: liveResult, arabic: widget.s.arabic),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onOpenAccount,
            icon: const Icon(Icons.person_rounded),
            label: Text(widget.s.arabic ? 'افتح طلباتي' : 'Open my requests'),
          ),
        ],
      ],
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.s,
    required this.orders,
    required this.liveOrders,
    required this.backendConfigured,
    required this.backendSignedIn,
    required this.userEmail,
    required this.backendBusy,
    required this.backendNotice,
    required this.onLanguageToggle,
    required this.onStartRequest,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onSignOut,
    required this.onRefreshLiveOrders,
  });

  final EventoStrings s;
  final List<DemoOrder> orders;
  final List<ProjectRequestRecord> liveOrders;
  final bool backendConfigured;
  final bool backendSignedIn;
  final String? userEmail;
  final bool backendBusy;
  final String? backendNotice;
  final VoidCallback onLanguageToggle;
  final ProjectRequestOpener onStartRequest;
  final Future<bool> Function(String email) onSendOtp;
  final Future<bool> Function(String email, String token) onVerifyOtp;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onRefreshLiveOrders;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool otpSent = false;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: <Widget>[
        _SectionHeader(title: widget.s.account),
        const SizedBox(height: 12),
        if (!widget.backendConfigured)
          _EmptyState(
            icon: Icons.cloud_off_rounded,
            text: widget.s.arabic ? 'هذه النسخة تعمل في وضع Demo محلي.' : 'This build is running in local demo mode.',
          )
        else if (!widget.backendSignedIn)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.s.arabic ? 'EVENTO Live Beta' : 'EVENTO Live Beta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(widget.s.arabic ? 'سجّل الدخول بالبريد لحفظ الطلبات الحقيقية ومتابعتها.' : 'Sign in by email to save and track real requests.'),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: widget.s.arabic ? 'البريد الإلكتروني' : 'Email'),
                  ),
                  const SizedBox(height: 10),
                  if (otpSent)
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: widget.s.arabic ? 'رمز OTP' : 'OTP code'),
                    ),
                  if (otpSent) const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: widget.backendBusy
                        ? null
                        : () async {
                            if (!otpSent) {
                              final bool sent = await widget.onSendOtp(emailController.text);
                              if (mounted && sent) setState(() => otpSent = true);
                            } else {
                              await widget.onVerifyOtp(emailController.text, otpController.text);
                            }
                          },
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(otpSent
                        ? (widget.s.arabic ? 'تحقق وسجّل الدخول' : 'Verify & sign in')
                        : (widget.s.arabic ? 'أرسل رمز الدخول' : 'Send sign-in code')),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
              title: Text(widget.userEmail ?? 'EVENTO user'),
              subtitle: Text(widget.s.arabic ? 'متصل بـ EVENTO Live' : 'Connected to EVENTO Live'),
              trailing: IconButton(
                tooltip: widget.s.arabic ? 'تسجيل الخروج' : 'Sign out',
                onPressed: widget.backendBusy ? null : widget.onSignOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ),
          ),
        if (widget.backendNotice != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(widget.backendNotice!, style: const TextStyle(color: EventoColors.gold)),
        ],
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            Expanded(child: _SectionHeader(title: widget.s.arabic ? 'الطلبات' : 'Requests')),
            if (widget.backendSignedIn)
              IconButton(
                tooltip: widget.s.arabic ? 'تحديث' : 'Refresh',
                onPressed: widget.backendBusy ? null : widget.onRefreshLiveOrders,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.backendSignedIn && widget.liveOrders.isNotEmpty)
          ...widget.liveOrders.map((ProjectRequestRecord order) => _LiveOrderCard(order: order, arabic: widget.s.arabic))
        else if (widget.orders.isNotEmpty)
          ...widget.orders.map((DemoOrder order) => _DemoOrderCard(order: order, arabic: widget.s.arabic))
        else
          _EmptyState(
            icon: Icons.inbox_outlined,
            text: widget.s.arabic ? 'لا توجد طلبات بعد. ابدأ بتحليل فكرة.' : 'No requests yet. Start by analyzing an idea.',
          ),
        const SizedBox(height: 18),
        FilledButton.tonalIcon(
          onPressed: () => widget.onStartRequest(),
          icon: const Icon(Icons.add_rounded),
          label: Text(widget.s.startProject),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onLanguageToggle,
          icon: const Icon(Icons.translate_rounded),
          label: Text(widget.s.language),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.order, required this.live, required this.arabic});

  final DemoOrder order;
  final ProjectRequestRecord? live;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final DemoAnalysisResult a = order.analysis;
    final List<String> scope = arabic ? a.scopeAr : a.scopeEn;
    final List<String> risks = arabic ? a.risksAr : a.risksEn;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(live?.requestCode ?? order.id, style: const TextStyle(color: EventoColors.cyan, fontWeight: FontWeight.w900)),
                ),
                _StatusPill(icon: Icons.analytics_outlined, label: arabic ? a.complexityAr : a.complexityEn),
              ],
            ),
            const SizedBox(height: 12),
            Text(order.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(arabic ? a.summaryAr : a.summaryEn),
            const SizedBox(height: 16),
            Text(arabic ? 'نطاق MVP المقترح' : 'Suggested MVP scope', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...scope.map((String item) => _Bullet(text: item, icon: Icons.check_circle_outline_rounded)),
            const SizedBox(height: 14),
            Text(arabic ? 'مخاطر يجب ضبطها' : 'Risks to control', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...risks.map((String item) => _Bullet(text: item, icon: Icons.shield_outlined)),
            const SizedBox(height: 14),
            Text(arabic ? a.nextAr : a.nextEn, style: const TextStyle(color: EventoColors.gold)),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.arabic, required this.onRequest});

  final PortfolioProject project;
  final bool arabic;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRequest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(project.label(arabic), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                  const Icon(Icons.arrow_forward_rounded, color: EventoColors.cyan),
                ],
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _MiniTag(project.category),
                  _MiniTag(project.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(project.summary(arabic), maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EventoColors.muted)),
              const Spacer(),
              Text(arabic ? 'ابدأ مشروعًا مشابهًا' : 'Request a similar project', style: const TextStyle(color: EventoColors.blue, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoOrderCard extends StatelessWidget {
  const _DemoOrderCard({required this.order, required this.arabic});
  final DemoOrder order;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.phone_android_rounded, color: EventoColors.gold),
          title: Text(order.title),
          subtitle: Text('${order.id} • ${arabic ? 'تحليل محلي' : 'Local analysis'}'),
        ),
      ),
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  const _LiveOrderCard({required this.order, required this.arabic});
  final ProjectRequestRecord order;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_done_rounded, color: EventoColors.cyan),
          title: Text(order.title),
          subtitle: Text('${order.requestCode} • ${order.status.name}'),
          trailing: Text(arabic ? 'LIVE' : 'LIVE', style: const TextStyle(color: EventoColors.cyan, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: EventoColors.panelSoft, borderRadius: BorderRadius.circular(999)),
            child: Text(trailing!, style: const TextStyle(color: EventoColors.cyan, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EventoColors.cyan.withValues(alpha: 0.1),
        border: Border.all(color: EventoColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: EventoColors.cyan),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(color: EventoColors.cyan, fontSize: 11, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: EventoColors.panelSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: EventoColors.muted)),
    );
  }
}

class _ProcessTile extends StatelessWidget {
  const _ProcessTile({required this.icon, required this.number, required this.ar, required this.en});
  final IconData icon;
  final String number;
  final String ar;
  final String en;

  @override
  Widget build(BuildContext context) {
    final bool arabic = Directionality.of(context) == TextDirection.rtl;
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: EventoColors.panel, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: <Widget>[
          Icon(icon, color: EventoColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(number, style: const TextStyle(color: EventoColors.gold, fontSize: 10, fontWeight: FontWeight.w900)),
                Text(arabic ? ar : en, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: EventoColors.cyan),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: EventoColors.panel, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 38, color: EventoColors.muted),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: EventoColors.muted)),
        ],
      ),
    );
  }
}
