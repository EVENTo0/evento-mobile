import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/backend_config.dart';
import 'core/evento_theme.dart';
import 'data/auth_service.dart';
import 'data/demo_analysis.dart';
import 'data/mock_data.dart';
import 'data/portfolio_catalog.dart';
import 'data/repositories/project_request_repository.dart';
import 'domain/portfolio_project.dart';
import 'domain/project_request.dart';

class EventoRc3App extends StatefulWidget {
  const EventoRc3App({super.key});

  @override
  State<EventoRc3App> createState() => _EventoRc3AppState();
}

class _EventoRc3AppState extends State<EventoRc3App> {
  bool arabic = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EVENTO',
      theme: buildEventoTheme(),
      home: _EventoRc3Shell(
        arabic: arabic,
        onToggleLanguage: () => setState(() => arabic = !arabic),
      ),
    );
  }
}

class _EventoRc3Shell extends StatefulWidget {
  const _EventoRc3Shell({required this.arabic, required this.onToggleLanguage});

  final bool arabic;
  final VoidCallback onToggleLanguage;

  @override
  State<_EventoRc3Shell> createState() => _EventoRc3ShellState();
}

class _EventoRc3ShellState extends State<_EventoRc3Shell> {
  int tab = 0;
  final List<DemoOrder> localOrders = <DemoOrder>[];
  final List<ProjectRequestRecord> liveOrders = <ProjectRequestRecord>[];
  PortfolioProject? selectedProject;
  SupabaseAuthService? auth;
  SupabaseProjectRequestRepository? repository;
  String? email;
  String? backendNotice;
  bool busy = false;

  bool get liveConfigured => BackendConfig.isConfigured;
  bool get signedIn => email != null;

  @override
  void initState() {
    super.initState();
    if (liveConfigured) {
      final SupabaseClient client = Supabase.instance.client;
      auth = SupabaseAuthService(client);
      repository = SupabaseProjectRequestRepository(client);
      email = client.auth.currentUser?.email;
      if (email != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLiveOrders());
      }
    }
  }

  void _openRequest([PortfolioProject? project]) {
    setState(() {
      selectedProject = project;
      tab = 3;
    });
  }

  Future<bool> _sendOtp(String value) async {
    final SupabaseAuthService? service = auth;
    if (service == null) return false;
    setState(() {
      busy = true;
      backendNotice = null;
    });
    try {
      await service.sendEmailOtp(value);
      if (mounted) {
        setState(() => backendNotice = widget.arabic
            ? 'تم إرسال رمز/رابط الدخول إلى بريدك.'
            : 'A sign-in code/link was sent to your email.');
      }
      return true;
    } catch (error) {
      if (mounted) setState(() => backendNotice = '$error');
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> _verifyOtp(String value, String token) async {
    final SupabaseAuthService? service = auth;
    if (service == null) return false;
    setState(() {
      busy = true;
      backendNotice = null;
    });
    try {
      final User? user = await service.verifyEmailOtp(email: value, token: token);
      if (user == null) return false;
      if (!mounted) return true;
      setState(() {
        email = user.email ?? value.trim();
        backendNotice = widget.arabic ? 'تم تسجيل الدخول إلى EVENTO Live.' : 'Signed in to EVENTO Live.';
      });
      await _refreshLiveOrders();
      return true;
    } catch (error) {
      if (mounted) setState(() => backendNotice = '$error');
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signOut() async {
    final SupabaseAuthService? service = auth;
    if (service == null) return;
    await service.signOut();
    if (!mounted) return;
    setState(() {
      email = null;
      liveOrders.clear();
      backendNotice = widget.arabic ? 'تم تسجيل الخروج.' : 'Signed out.';
    });
  }

  Future<void> _refreshLiveOrders() async {
    final SupabaseProjectRequestRepository? repo = repository;
    if (repo == null || !signedIn) return;
    setState(() => busy = true);
    try {
      final List<ProjectRequestRecord> rows = await repo.listMine();
      if (!mounted) return;
      setState(() {
        liveOrders
          ..clear()
          ..addAll(rows);
      });
    } catch (error) {
      if (mounted) setState(() => backendNotice = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<ProjectRequestRecord> _submitLive(DemoOrder order) async {
    final SupabaseProjectRequestRepository? repo = repository;
    if (repo == null || !signedIn) throw const AuthenticationRequiredException();
    final ProjectRequestRecord created = await repo.create(
      type: order.type,
      title: order.title,
      details: order.details,
      sourceProjectId: order.sourceProjectId,
    );
    try {
      await repo.requestAnalysis(created.id);
    } catch (error) {
      if (mounted) {
        setState(() => backendNotice = widget.arabic
            ? 'تم حفظ ${created.requestCode}، والتحليل الخادمي ما زال معلقًا: $error'
            : '${created.requestCode} was saved; server analysis is still pending: $error');
      }
    }
    final ProjectRequestRecord result = await repo.getById(created.id) ?? created;
    await _refreshLiveOrders();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _HomePage(arabic: widget.arabic, onRequest: _openRequest, onProjects: () => setState(() => tab = 2)),
      _ServicesPage(arabic: widget.arabic, onRequest: _openRequest),
      _ProjectsPage(arabic: widget.arabic, onRequest: _openRequest),
      _RequestPage(
        key: ValueKey<String?>(selectedProject?.id),
        arabic: widget.arabic,
        seed: selectedProject,
        liveConfigured: liveConfigured,
        signedIn: signedIn,
        onLocalOrder: (DemoOrder order) => setState(() => localOrders.insert(0, order)),
        onLiveSubmit: signedIn ? _submitLive : null,
        onOpenAccount: () => setState(() => tab = 4),
      ),
      _AccountPage(
        arabic: widget.arabic,
        liveConfigured: liveConfigured,
        signedIn: signedIn,
        email: email,
        busy: busy,
        notice: backendNotice,
        localOrders: localOrders,
        liveOrders: liveOrders,
        onSendOtp: _sendOtp,
        onVerifyOtp: _verifyOtp,
        onSignOut: _signOut,
        onRefresh: _refreshLiveOrders,
        onNewRequest: _openRequest,
      ),
    ];

    return Directionality(
      textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: <Widget>[
              _EventoMark(),
              SizedBox(width: 10),
              Text('EVENTO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.6)),
            ],
          ),
          actions: <Widget>[
            _LiveBadge(live: liveConfigured),
            IconButton(
              tooltip: widget.arabic ? 'English' : 'العربية',
              onPressed: widget.onToggleLanguage,
              icon: const Icon(Icons.translate_rounded),
            ),
          ],
        ),
        body: IndexedStack(index: tab, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (int value) => setState(() => tab = value),
          destinations: <NavigationDestination>[
            NavigationDestination(icon: const Icon(Icons.home_outlined), label: widget.arabic ? 'الرئيسية' : 'Home'),
            NavigationDestination(icon: const Icon(Icons.grid_view_outlined), label: widget.arabic ? 'الخدمات' : 'Services'),
            NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: widget.arabic ? 'المشاريع' : 'Projects'),
            NavigationDestination(icon: const Icon(Icons.add_circle_outline), label: widget.arabic ? 'اطلب' : 'Request'),
            NavigationDestination(icon: const Icon(Icons.person_outline), label: widget.arabic ? 'حسابي' : 'Account'),
          ],
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.arabic, required this.onRequest, required this.onProjects});

  final bool arabic;
  final void Function([PortfolioProject?]) onRequest;
  final VoidCallback onProjects;

  @override
  Widget build(BuildContext context) {
    final List<PortfolioProject> featured = portfolioProjects
        .where((PortfolioProject p) => p.status == 'active' || p.status == 'under-development')
        .take(4)
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: <Color>[Color(0xFF103A5D), Color(0xFF071522)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _Pill(text: 'EVENTO LIVE BETA', icon: Icons.auto_awesome_rounded),
              const SizedBox(height: 18),
              Text(
                arabic ? 'نحوّل فكرتك إلى منتج جاهز للتجربة' : 'Turn your idea into a product ready to test',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                arabic
                    ? 'حلّل الفكرة، اختر من مشاريع EVENTO، تابع الطلب، وجرّب كل تحديث من هاتفك.'
                    : 'Analyze the idea, explore EVENTO projects, track the request, and test every update from your phone.',
                style: const TextStyle(color: EventoColors.muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: () => onRequest(), icon: const Icon(Icons.bolt_rounded), label: Text(arabic ? 'حلّل فكرتي' : 'Analyze my idea')),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: onProjects, icon: const Icon(Icons.inventory_2_outlined), label: Text(arabic ? 'استعرض المشاريع' : 'Browse projects')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _TitleRow(title: arabic ? 'مشاريع مختارة' : 'Featured projects', count: '${portfolioProjects.length}'),
        const SizedBox(height: 12),
        ...featured.map((PortfolioProject project) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProjectTile(project: project, arabic: arabic, onTap: () => onRequest(project)),
            )),
        const SizedBox(height: 14),
        _TitleRow(title: arabic ? 'كيف تعمل EVENTO؟' : 'How EVENTO works'),
        const SizedBox(height: 10),
        _InfoTile(icon: Icons.lightbulb_outline, title: arabic ? '1. الفكرة' : '1. Idea', text: arabic ? 'اكتب ما تريد بناءه.' : 'Describe what you want to build.'),
        _InfoTile(icon: Icons.psychology_alt_outlined, title: arabic ? '2. التحليل' : '2. Analysis', text: arabic ? 'نستخرج النطاق والمخاطر والقدرات.' : 'We identify scope, risks, and capabilities.'),
        _InfoTile(icon: Icons.phone_android_rounded, title: arabic ? '3. البناء والتجربة' : '3. Build & test', text: arabic ? 'تصل النسخ إلى هاتفك للاختبار المستمر.' : 'Builds reach your phone for continuous testing.'),
      ],
    );
  }
}

class _ServicesPage extends StatelessWidget {
  const _ServicesPage({required this.arabic, required this.onRequest});
  final bool arabic;
  final void Function([PortfolioProject?]) onRequest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _TitleRow(title: arabic ? 'خدمات EVENTO' : 'EVENTO Services'),
        const SizedBox(height: 12),
        ...services.map((ServiceItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Icon(item.icon, color: EventoColors.cyan),
                  title: Text(arabic ? item.ar : item.en, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(arabic ? item.detailAr : item.detailEn),
                  trailing: IconButton(onPressed: () => onRequest(), icon: const Icon(Icons.arrow_forward_rounded)),
                ),
              ),
            )),
      ],
    );
  }
}

class _ProjectsPage extends StatefulWidget {
  const _ProjectsPage({required this.arabic, required this.onRequest});
  final bool arabic;
  final void Function([PortfolioProject?]) onRequest;

  @override
  State<_ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<_ProjectsPage> {
  String query = '';
  String status = 'all';

  @override
  Widget build(BuildContext context) {
    final List<String> statuses = <String>{'all', ...portfolioProjects.map((PortfolioProject p) => p.status)}.toList()..sort();
    final List<PortfolioProject> shown = portfolioProjects.where((PortfolioProject project) {
      return project.matches(query) && (status == 'all' || project.status == status);
    }).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _TitleRow(title: widget.arabic ? 'سجل المشاريع والمنتجات' : 'Project & product registry', count: '${shown.length}/${portfolioProjects.length}'),
        const SizedBox(height: 12),
        TextField(
          onChanged: (String value) => setState(() => query = value),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: widget.arabic ? 'ابحث عن مشروع' : 'Search projects'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: status,
          decoration: InputDecoration(labelText: widget.arabic ? 'الحالة' : 'Status'),
          items: statuses.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value == 'all' ? (widget.arabic ? 'كل الحالات' : 'All statuses') : value))).toList(),
          onChanged: (String? value) => setState(() => status = value ?? 'all'),
        ),
        const SizedBox(height: 14),
        ...shown.map((PortfolioProject project) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProjectTile(project: project, arabic: widget.arabic, onTap: () => widget.onRequest(project)),
            )),
      ],
    );
  }
}

class _RequestPage extends StatefulWidget {
  const _RequestPage({
    super.key,
    required this.arabic,
    required this.seed,
    required this.liveConfigured,
    required this.signedIn,
    required this.onLocalOrder,
    required this.onLiveSubmit,
    required this.onOpenAccount,
  });

  final bool arabic;
  final PortfolioProject? seed;
  final bool liveConfigured;
  final bool signedIn;
  final ValueChanged<DemoOrder> onLocalOrder;
  final Future<ProjectRequestRecord> Function(DemoOrder)? onLiveSubmit;
  final VoidCallback onOpenAccount;

  @override
  State<_RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<_RequestPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController title = TextEditingController();
  final TextEditingController details = TextEditingController();
  String type = 'Mobile App';
  bool busy = false;
  DemoOrder? result;
  ProjectRequestRecord? liveResult;
  String? warning;

  @override
  void initState() {
    super.initState();
    final PortfolioProject? seed = widget.seed;
    if (seed != null) {
      title.text = widget.arabic ? 'مشروع مستوحى من ${seed.nameAr}' : 'Project inspired by ${seed.name}';
      details.text = widget.arabic
          ? 'أريد مشروعًا مشابهًا لـ ${seed.nameAr} مع تخصيصه لاحتياجي. ${seed.summaryAr}'
          : 'I want a project inspired by ${seed.name}, customized to my needs. ${seed.summaryEn}';
    }
  }

  @override
  void dispose() {
    title.dispose();
    details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      warning = null;
    });
    final DemoOrder order = createDemoOrder(type: type, title: title.text, details: details.text, sourceProjectId: widget.seed?.id);
    try {
      final Future<ProjectRequestRecord> Function(DemoOrder)? submitLive = widget.onLiveSubmit;
      if (submitLive == null) {
        widget.onLocalOrder(order);
        if (mounted) setState(() => result = order);
      } else {
        final ProjectRequestRecord serverOrder = await submitLive(order);
        if (mounted) setState(() {
          result = order;
          liveResult = serverOrder;
        });
      }
    } catch (error) {
      widget.onLocalOrder(order);
      if (mounted) setState(() {
        result = order;
        warning = widget.arabic ? 'حُفظ التحليل محليًا لأن الاتصال الحي تعذر: $error' : 'Saved locally because the live request failed: $error';
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool liveReady = widget.liveConfigured && widget.signedIn;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _TitleRow(title: widget.arabic ? 'حلّل فكرة مشروعك' : 'Analyze your project idea'),
        const SizedBox(height: 10),
        _Pill(
          text: liveReady
              ? (widget.arabic ? 'LIVE — سيُحفظ الطلب' : 'LIVE — request will be saved')
              : (widget.arabic ? 'DEMO SAFE — تحليل محلي' : 'DEMO SAFE — local analysis'),
          icon: liveReady ? Icons.cloud_done : Icons.phone_android,
        ),
        const SizedBox(height: 14),
        Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(labelText: widget.arabic ? 'نوع المشروع' : 'Project type'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'Mobile App', child: Text('Mobile App')),
                  DropdownMenuItem<String>(value: 'Website', child: Text('Website / Platform')),
                  DropdownMenuItem<String>(value: 'AI', child: Text('AI Solution')),
                  DropdownMenuItem<String>(value: 'Game', child: Text('Game / XR')),
                ],
                onChanged: (String? value) => setState(() => type = value ?? type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: title,
                decoration: InputDecoration(labelText: widget.arabic ? 'عنوان الفكرة' : 'Idea title'),
                validator: (String? value) => (value?.trim().length ?? 0) < 4 ? (widget.arabic ? 'اكتب عنوانًا أوضح.' : 'Enter a clearer title.') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: details,
                minLines: 5,
                maxLines: 10,
                decoration: InputDecoration(labelText: widget.arabic ? 'اشرح ما تريد بناءه' : 'Describe what you want to build'),
                validator: (String? value) => (value?.trim().length ?? 0) < 25 ? (widget.arabic ? 'أضف تفاصيل أكثر.' : 'Add more detail.') : null,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : _submit,
                  icon: busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.psychology_alt_rounded),
                  label: Text(widget.arabic ? 'حلّل وأنشئ الطلب' : 'Analyze & create request'),
                ),
              ),
            ],
          ),
        ),
        if (warning != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(warning!, style: const TextStyle(color: EventoColors.gold)),
        ],
        if (result != null) ...<Widget>[
          const SizedBox(height: 18),
          _AnalysisResult(order: result!, liveResult: liveResult, arabic: widget.arabic),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: widget.onOpenAccount, icon: const Icon(Icons.person), label: Text(widget.arabic ? 'افتح طلباتي' : 'Open my requests')),
        ],
      ],
    );
  }
}

class _AccountPage extends StatefulWidget {
  const _AccountPage({
    required this.arabic,
    required this.liveConfigured,
    required this.signedIn,
    required this.email,
    required this.busy,
    required this.notice,
    required this.localOrders,
    required this.liveOrders,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onSignOut,
    required this.onRefresh,
    required this.onNewRequest,
  });

  final bool arabic;
  final bool liveConfigured;
  final bool signedIn;
  final String? email;
  final bool busy;
  final String? notice;
  final List<DemoOrder> localOrders;
  final List<ProjectRequestRecord> liveOrders;
  final Future<bool> Function(String) onSendOtp;
  final Future<bool> Function(String, String) onVerifyOtp;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onRefresh;
  final void Function([PortfolioProject?]) onNewRequest;

  @override
  State<_AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<_AccountPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController otp = TextEditingController();
  bool otpSent = false;

  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _TitleRow(title: widget.arabic ? 'حساب EVENTO' : 'EVENTO Account'),
        const SizedBox(height: 12),
        if (!widget.liveConfigured)
          _InfoTile(icon: Icons.cloud_off, title: 'Demo', text: widget.arabic ? 'الـBackend غير مفعّل في هذا البناء.' : 'Backend is not configured in this build.')
        else if (!widget.signedIn)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.arabic ? 'تسجيل الدخول إلى Live Beta' : 'Sign in to Live Beta', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: widget.arabic ? 'البريد الإلكتروني' : 'Email')),
                  if (otpSent) ...<Widget>[
                    const SizedBox(height: 10),
                    TextField(controller: otp, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: widget.arabic ? 'رمز OTP' : 'OTP code')),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: widget.busy
                        ? null
                        : () async {
                            if (!otpSent) {
                              final bool sent = await widget.onSendOtp(email.text);
                              if (mounted && sent) setState(() => otpSent = true);
                            } else {
                              await widget.onVerifyOtp(email.text, otp.text);
                            }
                          },
                    child: Text(otpSent ? (widget.arabic ? 'تحقق' : 'Verify') : (widget.arabic ? 'أرسل رمز الدخول' : 'Send sign-in code')),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(widget.email ?? 'EVENTO user'),
              subtitle: const Text('EVENTO Live'),
              trailing: IconButton(onPressed: widget.busy ? null : widget.onSignOut, icon: const Icon(Icons.logout)),
            ),
          ),
        if (widget.notice != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(widget.notice!, style: const TextStyle(color: EventoColors.gold)),
        ],
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(child: _TitleRow(title: widget.arabic ? 'طلباتي' : 'My requests')),
            if (widget.signedIn) IconButton(onPressed: widget.busy ? null : widget.onRefresh, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.signedIn && widget.liveOrders.isNotEmpty)
          ...widget.liveOrders.map((ProjectRequestRecord item) => Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_done, color: EventoColors.cyan),
                  title: Text(item.title),
                  subtitle: Text('${item.requestCode} • ${item.status.name}'),
                ),
              ))
        else if (widget.localOrders.isNotEmpty)
          ...widget.localOrders.map((DemoOrder item) => Card(
                child: ListTile(
                  leading: const Icon(Icons.phone_android, color: EventoColors.gold),
                  title: Text(item.title),
                  subtitle: Text('${item.id} • ${widget.arabic ? 'تحليل محلي' : 'Local analysis'}'),
                ),
              ))
        else
          _InfoTile(icon: Icons.inbox_outlined, title: widget.arabic ? 'لا توجد طلبات' : 'No requests', text: widget.arabic ? 'ابدأ بتحليل فكرة جديدة.' : 'Start by analyzing a new idea.'),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(onPressed: () => widget.onNewRequest(), icon: const Icon(Icons.add), label: Text(widget.arabic ? 'طلب جديد' : 'New request')),
      ],
    );
  }
}

class _AnalysisResult extends StatelessWidget {
  const _AnalysisResult({required this.order, required this.liveResult, required this.arabic});
  final DemoOrder order;
  final ProjectRequestRecord? liveResult;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final DemoAnalysisResult analysis = order.analysis;
    final List<String> scope = arabic ? analysis.scopeAr : analysis.scopeEn;
    final List<String> risks = arabic ? analysis.risksAr : analysis.risksEn;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(liveResult?.requestCode ?? order.id, style: const TextStyle(color: EventoColors.cyan, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(order.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
            const SizedBox(height: 8),
            Text(arabic ? analysis.summaryAr : analysis.summaryEn),
            const SizedBox(height: 14),
            Text(arabic ? 'نطاق MVP المقترح' : 'Suggested MVP scope', style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            ...scope.map((String item) => _Bullet(text: item)),
            const SizedBox(height: 12),
            Text(arabic ? 'مخاطر يجب ضبطها' : 'Risks to control', style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            ...risks.map((String item) => _Bullet(text: item, warning: true)),
            const SizedBox(height: 12),
            Text(arabic ? analysis.nextAr : analysis.nextEn, style: const TextStyle(color: EventoColors.gold)),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.arabic, required this.onTap});
  final PortfolioProject project;
  final bool arabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(project.label(arabic), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                  const Icon(Icons.arrow_forward_rounded, color: EventoColors.cyan),
                ],
              ),
              const SizedBox(height: 6),
              Text('${project.category} • ${project.status}', style: const TextStyle(color: EventoColors.cyan, fontSize: 11)),
              const SizedBox(height: 8),
              Text(project.summary(arabic), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EventoColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, this.count});
  final String title;
  final String? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        if (count != null) _Pill(text: count!, icon: Icons.layers_outlined),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: EventoColors.cyan),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(text),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(warning ? Icons.shield_outlined : Icons.check_circle_outline, size: 18, color: warning ? EventoColors.gold : EventoColors.cyan),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: EventoColors.cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: EventoColors.cyan),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: EventoColors.cyan, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: _Pill(text: live ? 'LIVE' : 'DEMO', icon: live ? Icons.cloud_done : Icons.offline_bolt),
    );
  }
}

class _EventoMark extends StatelessWidget {
  const _EventoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(colors: <Color>[EventoColors.blue, EventoColors.cyan]),
      ),
      alignment: Alignment.center,
      child: const Text('E', style: TextStyle(color: EventoColors.ink, fontWeight: FontWeight.w900, fontSize: 19)),
    );
  }
}
