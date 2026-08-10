import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/backend_config.dart';
import 'core/evento_theme.dart';
import 'data/portfolio_catalog.dart';
import 'data/repositories/project_request_repository.dart';
import 'domain/portfolio_project.dart';
import 'domain/project_request.dart';
import 'domain/request_live_detail.dart';

class EventoRc5App extends StatefulWidget {
  const EventoRc5App({super.key});

  @override
  State<EventoRc5App> createState() => _EventoRc5AppState();
}

class _EventoRc5AppState extends State<EventoRc5App> {
  bool arabic = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EVENTO RC5',
      theme: buildEventoTheme(),
      home: Directionality(
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        child: _Rc5Shell(
          arabic: arabic,
          onToggleLanguage: () => setState(() => arabic = !arabic),
        ),
      ),
    );
  }
}

class _Rc5Shell extends StatefulWidget {
  const _Rc5Shell({required this.arabic, required this.onToggleLanguage});

  final bool arabic;
  final VoidCallback onToggleLanguage;

  @override
  State<_Rc5Shell> createState() => _Rc5ShellState();
}

class _Rc5ShellState extends State<_Rc5Shell> {
  int tab = 0;
  PortfolioProject? selectedProject;
  late final SupabaseClient? client;
  SupabaseProjectRequestRepository? repository;
  final List<ProjectRequestRecord> liveOrders = <ProjectRequestRecord>[];
  bool busy = false;
  String? notice;

  bool get configured => BackendConfig.isConfigured;
  bool get signedIn => client?.auth.currentUser != null;
  User? get currentUser => client?.auth.currentUser;

  @override
  void initState() {
    super.initState();
    client = configured ? Supabase.instance.client : null;
    if (client != null) repository = SupabaseProjectRequestRepository(client!);
    if (signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOrders());
    }
  }

  Future<void> _anonymousSignIn() async {
    final SupabaseClient? supabase = client;
    if (supabase == null) return;
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      final AuthResponse response = await supabase.auth.signInAnonymously();
      if (response.user == null) {
        throw StateError('Anonymous sign-in returned no user.');
      }
      if (!mounted) return;
      setState(() {
        notice = widget.arabic
            ? 'تم الدخول التجريبي إلى EVENTO Live.'
            : 'Signed in to EVENTO Live as a test guest.';
      });
      await _refreshOrders();
    } catch (error) {
      if (mounted) setState(() => notice = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signOut() async {
    final SupabaseClient? supabase = client;
    if (supabase == null) return;
    await supabase.auth.signOut();
    if (!mounted) return;
    setState(() {
      liveOrders.clear();
      notice = widget.arabic ? 'تم تسجيل الخروج.' : 'Signed out.';
    });
  }

  Future<void> _refreshOrders() async {
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
      if (mounted) setState(() => notice = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<ProjectRequestRecord> _createLiveRequest({
    required String type,
    required String title,
    required String details,
  }) async {
    final SupabaseProjectRequestRepository? repo = repository;
    if (repo == null || !signedIn) {
      throw const AuthenticationRequiredException();
    }
    final ProjectRequestRecord created = await repo.create(
      type: type,
      title: title,
      details: details,
      sourceProjectId: selectedProject?.id,
    );
    await repo.requestAnalysis(created.id);
    final ProjectRequestRecord result = await repo.getById(created.id) ?? created;
    await _refreshOrders();
    return result;
  }

  void _requestFromProject([PortfolioProject? project]) {
    setState(() {
      selectedProject = project;
      tab = 3;
    });
  }

  Future<void> _openLiveDetail(ProjectRequestRecord order) async {
    final SupabaseProjectRequestRepository? repo = repository;
    if (repo == null) return;
    setState(() => busy = true);
    try {
      final RequestAnalysisRecord? analysis = await repo.getAnalysis(order.id);
      final List<RequestEventRecord> events = await repo.getEvents(order.id);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => _RequestDetailPage(
            arabic: widget.arabic,
            order: order,
            initialAnalysis: analysis,
            initialEvents: events,
            repository: repo,
          ),
        ),
      );
      await _refreshOrders();
    } catch (error) {
      if (mounted) setState(() => notice = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _HomePage(
        arabic: widget.arabic,
        onRequest: _requestFromProject,
        onProjects: () => setState(() => tab = 2),
      ),
      _ServicesPage(arabic: widget.arabic, onRequest: _requestFromProject),
      _ProjectsPage(arabic: widget.arabic, onRequest: _requestFromProject),
      _RequestPage(
        key: ValueKey<String?>(selectedProject?.id),
        arabic: widget.arabic,
        seed: selectedProject,
        signedIn: signedIn,
        onOpenAccount: () => setState(() => tab = 4),
        onSubmit: _createLiveRequest,
      ),
      _AccountPage(
        arabic: widget.arabic,
        configured: configured,
        signedIn: signedIn,
        anonymous: currentUser?.isAnonymous ?? false,
        busy: busy,
        notice: notice,
        orders: liveOrders,
        onAnonymousSignIn: _anonymousSignIn,
        onSignOut: _signOut,
        onRefresh: _refreshOrders,
        onOpenOrder: _openLiveDetail,
        onNewRequest: _requestFromProject,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: EventoColors.cyan,
              child: Text('E', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            SizedBox(width: 10),
            Text('EVENTO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _Pill(
              text: configured ? 'LIVE RC5' : 'DEMO',
              icon: configured ? Icons.cloud_done : Icons.offline_bolt,
            ),
          ),
          IconButton(
            tooltip: widget.arabic ? 'English' : 'العربية',
            onPressed: widget.onToggleLanguage,
            icon: const Icon(Icons.translate),
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
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.arabic, required this.onRequest, required this.onProjects});

  final bool arabic;
  final void Function([PortfolioProject?]) onRequest;
  final VoidCallback onProjects;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          const _Pill(text: 'RC5 • BILINGUAL LIVE', icon: Icons.auto_awesome),
          const SizedBox(height: 16),
          Text(
            arabic ? 'مشروعك من الفكرة إلى خطة حيّة قابلة للتتبع' : 'Your project from idea to a live, trackable plan',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            arabic
                ? 'تحليل خادمي ثنائي اللغة، مخاطر، نطاق MVP وخط زمني حي — كله من هاتفك.'
                : 'Bilingual server analysis, risks, MVP scope, and live timeline — all from your phone.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => onRequest(),
            icon: const Icon(Icons.bolt),
            label: Text(arabic ? 'ابدأ طلبًا حيًا' : 'Start a live request'),
          ),
          OutlinedButton.icon(
            onPressed: onProjects,
            icon: const Icon(Icons.inventory_2),
            label: Text(arabic ? 'استعرض 50 مشروعًا' : 'Browse 50 projects'),
          ),
          const SizedBox(height: 22),
          _InfoCard(
            icon: Icons.translate,
            title: arabic ? 'تحليل عربي/إنجليزي' : 'Arabic/English analysis',
            text: arabic ? 'يحفظ الخادم اللغتين لنفس الطلب.' : 'The server stores both languages for the same request.',
          ),
          _InfoCard(
            icon: Icons.timeline,
            title: arabic ? 'Timeline حي' : 'Live timeline',
            text: arabic ? 'كل مرحلة مهمة تظهر داخل تفاصيل الطلب.' : 'Every important stage appears in the request details.',
          ),
        ],
      );
}

class _ServicesPage extends StatelessWidget {
  const _ServicesPage({required this.arabic, required this.onRequest});

  final bool arabic;
  final void Function([PortfolioProject?]) onRequest;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          Text(arabic ? 'خدمات EVENTO' : 'EVENTO Services', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          for (final ({IconData icon, String ar, String en}) item in <({IconData icon, String ar, String en})>[
            (icon: Icons.phone_android, ar: 'تطبيقات الهاتف', en: 'Mobile Apps'),
            (icon: Icons.language, ar: 'المواقع والمنصات', en: 'Web Platforms'),
            (icon: Icons.psychology, ar: 'حلول الذكاء الاصطناعي', en: 'AI Solutions'),
            (icon: Icons.sports_esports, ar: 'الألعاب والتجارب التفاعلية', en: 'Games & Interactive'),
          ])
            Card(
              child: ListTile(
                leading: Icon(item.icon, color: EventoColors.cyan),
                title: Text(arabic ? item.ar : item.en),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => onRequest(),
              ),
            ),
        ],
      );
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

  @override
  Widget build(BuildContext context) {
    final List<PortfolioProject> shown = portfolioProjects.where((PortfolioProject p) => p.matches(query)).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        Text(
          '${widget.arabic ? 'المشاريع' : 'Projects'} • ${shown.length}/${portfolioProjects.length}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (String value) => setState(() => query = value),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: widget.arabic ? 'ابحث عن مشروع' : 'Search projects'),
        ),
        const SizedBox(height: 12),
        for (final PortfolioProject project in shown)
          Card(
            child: ListTile(
              title: Text(project.label(widget.arabic), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(project.summary(widget.arabic), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => widget.onRequest(project),
            ),
          ),
      ],
    );
  }
}

class _RequestPage extends StatefulWidget {
  const _RequestPage({
    super.key,
    required this.arabic,
    required this.seed,
    required this.signedIn,
    required this.onOpenAccount,
    required this.onSubmit,
  });

  final bool arabic;
  final PortfolioProject? seed;
  final bool signedIn;
  final VoidCallback onOpenAccount;
  final Future<ProjectRequestRecord> Function({required String type, required String title, required String details}) onSubmit;

  @override
  State<_RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<_RequestPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController title = TextEditingController();
  final TextEditingController details = TextEditingController();
  String type = 'Mobile App';
  bool busy = false;
  String? error;
  ProjectRequestRecord? result;

  @override
  void initState() {
    super.initState();
    if (widget.seed != null) {
      title.text = widget.arabic ? 'مشروع مستوحى من ${widget.seed!.nameAr}' : 'Project inspired by ${widget.seed!.name}';
      details.text = widget.arabic
          ? 'أريد مشروعًا مشابهًا لـ ${widget.seed!.nameAr} مع تخصيصه لاحتياجي.'
          : 'I want a project inspired by ${widget.seed!.name}, customized to my needs.';
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
    if (!widget.signedIn) {
      widget.onOpenAccount();
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final ProjectRequestRecord order = await widget.onSubmit(type: type, title: title.text, details: details.text);
      if (mounted) setState(() => result = order);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          Text(widget.arabic ? 'حلّل وأنشئ طلبًا حيًا' : 'Analyze & create a live request', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _Pill(text: widget.signedIn ? 'LIVE • RC5 ENGINE' : 'SIGN IN REQUIRED', icon: widget.signedIn ? Icons.cloud_done : Icons.lock_outline),
          const SizedBox(height: 14),
          Form(
            key: formKey,
            child: Column(
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(labelText: widget.arabic ? 'نوع المشروع' : 'Project type'),
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
                  controller: title,
                  decoration: InputDecoration(labelText: widget.arabic ? 'عنوان الفكرة' : 'Idea title'),
                  validator: (String? value) => (value?.trim().length ?? 0) < 4 ? (widget.arabic ? 'اكتب عنوانًا أوضح.' : 'Enter a clearer title.') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: details,
                  minLines: 5,
                  maxLines: 9,
                  decoration: InputDecoration(labelText: widget.arabic ? 'اشرح ما تريد بناءه' : 'Describe what you want to build'),
                  validator: (String? value) => (value?.trim().length ?? 0) < 25 ? (widget.arabic ? 'أضف تفاصيل أكثر.' : 'Add more detail.') : null,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : _submit,
                    icon: const Icon(Icons.psychology_alt),
                    label: Text(widget.signedIn ? (widget.arabic ? 'حلّل وأنشئ الطلب' : 'Analyze & create request') : (widget.arabic ? 'اذهب إلى تسجيل الدخول' : 'Go to sign in')),
                  ),
                ),
              ],
            ),
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: EventoColors.gold))),
          if (result != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_done, color: EventoColors.cyan),
                  title: Text(result!.requestCode, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('${result!.title} • ${result!.status.name}'),
                  trailing: TextButton(onPressed: widget.onOpenAccount, child: Text(widget.arabic ? 'طلباتي' : 'My requests')),
                ),
              ),
            ),
        ],
      );
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({
    required this.arabic,
    required this.configured,
    required this.signedIn,
    required this.anonymous,
    required this.busy,
    required this.notice,
    required this.orders,
    required this.onAnonymousSignIn,
    required this.onSignOut,
    required this.onRefresh,
    required this.onOpenOrder,
    required this.onNewRequest,
  });

  final bool arabic;
  final bool configured;
  final bool signedIn;
  final bool anonymous;
  final bool busy;
  final String? notice;
  final List<ProjectRequestRecord> orders;
  final Future<void> Function() onAnonymousSignIn;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onRefresh;
  final Future<void> Function(ProjectRequestRecord) onOpenOrder;
  final void Function([PortfolioProject?]) onNewRequest;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          Text(arabic ? 'حساب EVENTO' : 'EVENTO Account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (!configured)
            _InfoCard(icon: Icons.cloud_off, title: 'Demo', text: arabic ? 'Backend غير مفعّل.' : 'Backend is not configured.')
          else if (!signedIn)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(arabic ? 'دخول Live Beta' : 'Live Beta sign-in', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(arabic ? 'للتجربة الحية فقط — سيزال قبل Production.' : 'Live testing only — removed before Production.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy ? null : onAnonymousSignIn,
                        icon: const Icon(Icons.bolt),
                        label: Text(arabic ? 'دخول تجريبي سريع' : 'Quick test sign-in'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(anonymous ? (arabic ? 'ضيف EVENTO التجريبي' : 'EVENTO Test Guest') : 'EVENTO User'),
                subtitle: const Text('Supabase Live • RLS protected'),
                trailing: IconButton(onPressed: busy ? null : onSignOut, icon: const Icon(Icons.logout)),
              ),
            ),
          if (notice != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(notice!, style: const TextStyle(color: EventoColors.gold))),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(child: Text(arabic ? 'طلباتي الحية' : 'My live requests', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
              if (signedIn) IconButton(onPressed: busy ? null : onRefresh, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          if (signedIn && orders.isNotEmpty)
            for (final ProjectRequestRecord order in orders)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_done, color: EventoColors.cyan),
                  title: Text(order.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${order.requestCode} • ${_localizedOrderStatus(order.status.name, arabic)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenOrder(order),
                ),
              )
          else
            _InfoCard(
              icon: Icons.inbox_outlined,
              title: arabic ? 'لا توجد طلبات' : 'No requests',
              text: arabic ? 'أنشئ طلبًا حيًا ثم سيظهر هنا.' : 'Create a live request and it will appear here.',
            ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(onPressed: () => onNewRequest(), icon: const Icon(Icons.add), label: Text(arabic ? 'طلب جديد' : 'New request')),
        ],
      );
}

class _RequestDetailPage extends StatefulWidget {
  const _RequestDetailPage({
    required this.arabic,
    required this.order,
    required this.initialAnalysis,
    required this.initialEvents,
    required this.repository,
  });

  final bool arabic;
  final ProjectRequestRecord order;
  final RequestAnalysisRecord? initialAnalysis;
  final List<RequestEventRecord> initialEvents;
  final SupabaseProjectRequestRepository repository;

  @override
  State<_RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<_RequestDetailPage> {
  RequestAnalysisRecord? analysis;
  late List<RequestEventRecord> events;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    analysis = widget.initialAnalysis;
    events = widget.initialEvents;
  }

  Future<void> _reload() async {
    final RequestAnalysisRecord? nextAnalysis = await widget.repository.getAnalysis(widget.order.id);
    final List<RequestEventRecord> nextEvents = await widget.repository.getEvents(widget.order.id);
    if (!mounted) return;
    setState(() {
      analysis = nextAnalysis;
      events = nextEvents;
    });
  }

  Future<void> _reanalyze() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.requestAnalysis(widget.order.id);
      await _reload();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final RequestAnalysisRecord? current = analysis;
    return Scaffold(
      appBar: AppBar(title: Text(widget.order.requestCode)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: <Widget>[
            _Pill(text: _localizedOrderStatus(widget.order.status.name, widget.arabic).toUpperCase(), icon: Icons.cloud_done),
            const SizedBox(height: 14),
            Text(widget.order.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(widget.order.details),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(child: Text(widget.arabic ? 'التحليل الخادمي' : 'Server analysis', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                IconButton(onPressed: busy ? null : _reload, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 10),
            if (current == null)
              _InfoCard(icon: Icons.hourglass_empty, title: widget.arabic ? 'التحليل قيد الانتظار' : 'Analysis pending', text: widget.arabic ? 'حدّث الطلب بعد قليل.' : 'Refresh the request shortly.')
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${widget.arabic ? 'التعقيد' : 'Complexity'}: ${_localizedComplexity(current.complexity, widget.arabic)}', style: const TextStyle(color: EventoColors.cyan, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(current.localizedSummary(widget.arabic)),
                      const SizedBox(height: 14),
                      Text(widget.arabic ? 'نطاق MVP' : 'MVP scope', style: const TextStyle(fontWeight: FontWeight.w900)),
                      for (final String item in current.localizedScope(widget.arabic)) _Bullet(text: item),
                      const SizedBox(height: 10),
                      Text(widget.arabic ? 'المخاطر' : 'Risks', style: const TextStyle(fontWeight: FontWeight.w900)),
                      for (final String item in current.localizedRisks(widget.arabic)) _Bullet(text: item, warning: true),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(child: Text('${widget.arabic ? 'المحرك' : 'Engine'}: ${current.engineVersion}', style: const TextStyle(color: EventoColors.muted, fontSize: 12))),
                          if (current.isRc5OrNewer) const Icon(Icons.verified, color: EventoColors.cyan, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (current != null && !current.isRc5OrNewer) ...<Widget>[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: busy ? null : _reanalyze,
                icon: const Icon(Icons.auto_awesome),
                label: Text(widget.arabic ? 'ترقية التحليل إلى RC5 ثنائي اللغة' : 'Upgrade analysis to bilingual RC5'),
              ),
            ],
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: EventoColors.gold))),
            const SizedBox(height: 20),
            Text(widget.arabic ? 'الخط الزمني' : 'Timeline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (events.isEmpty)
              _InfoCard(icon: Icons.timeline, title: widget.arabic ? 'لا توجد أحداث بعد' : 'No events yet', text: '')
            else
              for (final RequestEventRecord event in events.reversed)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: EventoColors.cyan),
                    title: Text(event.localizedStatus(widget.arabic), style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(event.localizedNote(widget.arabic)),
                    trailing: Text(_shortTime(event.createdAt), style: const TextStyle(fontSize: 11)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _localizedOrderStatus(String status, bool arabic) {
  if (!arabic) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'analyzed':
        return 'Analyzed';
      case 'awaiting_scope':
        return 'Awaiting scope';
      default:
        return status;
    }
  }
  switch (status) {
    case 'draft':
      return 'مسودة';
    case 'analyzed':
      return 'تم التحليل';
    case 'awaiting_scope':
      return 'بانتظار النطاق';
    default:
      return status;
  }
}

String _localizedComplexity(String complexity, bool arabic) {
  if (!arabic) return complexity.toUpperCase();
  switch (complexity) {
    case 'starter':
      return 'مبدئي';
    case 'medium':
      return 'متوسط';
    case 'advanced':
      return 'متقدم';
    case 'high':
      return 'عالٍ';
    default:
      return complexity;
  }
}

String _shortTime(DateTime value) {
  final DateTime local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: EventoColors.cyan),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: text.isEmpty ? null : Text(text),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: EventoColors.cyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: EventoColors.cyan),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: EventoColors.cyan, fontSize: 11, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 7),
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
