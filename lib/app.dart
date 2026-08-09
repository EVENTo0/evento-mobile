import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/backend_config.dart';
import 'core/evento_strings.dart';
import 'core/evento_theme.dart';
import 'data/auth_service.dart';
import 'data/demo_analysis.dart';
import 'data/repositories/project_request_repository.dart';
import 'domain/portfolio_project.dart';
import 'domain/project_request.dart';
import 'features/screens.dart';

class EventoApp extends StatefulWidget {
  const EventoApp({super.key});

  @override
  State<EventoApp> createState() => _EventoAppState();
}

class _EventoAppState extends State<EventoApp> {
  bool arabic = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EVENTO',
      theme: buildEventoTheme(),
      home: EventoShell(
        arabic: arabic,
        onLanguageToggle: () => setState(() => arabic = !arabic),
      ),
    );
  }
}

class EventoShell extends StatefulWidget {
  const EventoShell({
    super.key,
    required this.arabic,
    required this.onLanguageToggle,
  });

  final bool arabic;
  final VoidCallback onLanguageToggle;

  @override
  State<EventoShell> createState() => _EventoShellState();
}

class _EventoShellState extends State<EventoShell> {
  int index = 0;
  final List<DemoOrder> orders = <DemoOrder>[];
  final List<ProjectRequestRecord> liveOrders = <ProjectRequestRecord>[];
  PortfolioProject? requestSeed;
  int requestSeedRevision = 0;
  SupabaseAuthService? authService;
  SupabaseProjectRequestRepository? liveRepository;
  String? liveUserEmail;
  String? backendNotice;
  bool backendBusy = false;

  bool get backendConfigured => BackendConfig.isConfigured;
  bool get backendSignedIn => liveUserEmail != null;

  @override
  void initState() {
    super.initState();
    if (backendConfigured) {
      final SupabaseClient client = Supabase.instance.client;
      authService = SupabaseAuthService(client);
      liveRepository = SupabaseProjectRequestRepository(client);
      liveUserEmail = client.auth.currentUser?.email;
      if (liveUserEmail != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLiveOrders());
      }
    }
  }

  Future<bool> _sendOtp(String email) async {
    final SupabaseAuthService? auth = authService;
    if (auth == null) return false;
    setState(() {
      backendBusy = true;
      backendNotice = null;
    });
    try {
      await auth.sendEmailOtp(email);
      if (!mounted) return true;
      setState(() => backendNotice = widget.arabic
          ? 'تم إرسال رمز/رابط الدخول إلى البريد. أدخل رمز OTP إذا كان قالب البريد مضبوطًا لإرساله.'
          : 'Sign-in email sent. Enter the OTP when your email template is configured to include it.');
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => backendNotice =
            '${widget.arabic ? 'تعذر إرسال رمز الدخول' : 'Could not send sign-in code'}: $error');
      }
      return false;
    } finally {
      if (mounted) setState(() => backendBusy = false);
    }
  }

  Future<bool> _verifyOtp(String email, String token) async {
    final SupabaseAuthService? auth = authService;
    if (auth == null) return false;
    setState(() {
      backendBusy = true;
      backendNotice = null;
    });
    try {
      final User? user = await auth.verifyEmailOtp(email: email, token: token);
      if (user == null) throw StateError('No authenticated user returned.');
      if (!mounted) return true;
      setState(() {
        liveUserEmail = user.email ?? email.trim();
        backendNotice = widget.arabic
            ? 'تم تسجيل الدخول إلى EVENTO Live Beta.'
            : 'Signed in to EVENTO Live Beta.';
      });
      await _refreshLiveOrders();
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => backendNotice =
            '${widget.arabic ? 'تعذر التحقق من الرمز' : 'Could not verify the code'}: $error');
      }
      return false;
    } finally {
      if (mounted) setState(() => backendBusy = false);
    }
  }

  Future<void> _signOut() async {
    final SupabaseAuthService? auth = authService;
    if (auth == null) return;
    setState(() => backendBusy = true);
    try {
      await auth.signOut();
      if (!mounted) return;
      setState(() {
        liveUserEmail = null;
        liveOrders.clear();
        backendNotice = widget.arabic ? 'تم تسجيل الخروج.' : 'Signed out.';
      });
    } finally {
      if (mounted) setState(() => backendBusy = false);
    }
  }

  Future<void> _refreshLiveOrders() async {
    final SupabaseProjectRequestRepository? repository = liveRepository;
    if (repository == null || !backendSignedIn) return;
    setState(() => backendBusy = true);
    try {
      final List<ProjectRequestRecord> rows = await repository.listMine();
      if (!mounted) return;
      setState(() {
        liveOrders
          ..clear()
          ..addAll(rows);
        backendNotice = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => backendNotice =
            '${widget.arabic ? 'تعذر تحديث الطلبات الحقيقية' : 'Could not refresh live requests'}: $error');
      }
    } finally {
      if (mounted) setState(() => backendBusy = false);
    }
  }

  Future<ProjectRequestRecord> _submitLive(DemoOrder order) async {
    final SupabaseProjectRequestRepository? repository = liveRepository;
    if (repository == null || !backendSignedIn) {
      throw const AuthenticationRequiredException();
    }
    final ProjectRequestRecord created = await repository.create(
      type: order.type,
      title: order.title,
      details: order.details,
      sourceProjectId: order.sourceProjectId,
    );
    try {
      await repository.requestAnalysis(created.id);
    } catch (error) {
      if (mounted) {
        setState(() => backendNotice = widget.arabic
            ? 'تم حفظ الطلب ${created.requestCode}، لكن التحليل الخادمي ما زال معلقًا: $error'
            : 'Request ${created.requestCode} was saved, but server analysis is pending: $error');
      }
    }
    final ProjectRequestRecord refreshed = await repository.getById(created.id) ?? created;
    await _refreshLiveOrders();
    return refreshed;
  }

  void openRequest([PortfolioProject? project]) {
    setState(() {
      requestSeed = project;
      requestSeedRevision += 1;
      index = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final EventoStrings s = EventoStrings(widget.arabic);
    final List<Widget> pages = <Widget>[
      HomeScreen(
        s: s,
        onRequestTap: openRequest,
        onProjectsTap: () => setState(() => index = 2),
        onProjectRequest: openRequest,
      ),
      ServicesScreen(s: s, onRequestTap: openRequest),
      ProjectsScreen(s: s, onRequestProject: openRequest),
      RequestScreen(
        s: s,
        seedProject: requestSeed,
        seedRevision: requestSeedRevision,
        onOrderCreated: (DemoOrder order) => setState(() => orders.insert(0, order)),
        onOpenAccount: () => setState(() => index = 4),
        backendConfigured: backendConfigured,
        backendSignedIn: backendSignedIn,
        onLiveSubmit: backendSignedIn ? _submitLive : null,
      ),
      AccountScreen(
        s: s,
        orders: orders,
        liveOrders: liveOrders,
        backendConfigured: backendConfigured,
        backendSignedIn: backendSignedIn,
        userEmail: liveUserEmail,
        backendBusy: backendBusy,
        backendNotice: backendNotice,
        onLanguageToggle: widget.onLanguageToggle,
        onStartRequest: openRequest,
        onSendOtp: _sendOtp,
        onVerifyOtp: _verifyOtp,
        onSignOut: _signOut,
        onRefreshLiveOrders: _refreshLiveOrders,
      ),
    ];

    return Directionality(
      textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 18,
          title: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: const LinearGradient(
                    colors: <Color>[EventoColors.blue, EventoColors.cyan],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'E',
                    style: TextStyle(
                      color: EventoColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'EVENTO',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.8),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              tooltip: s.language,
              onPressed: widget.onLanguageToggle,
              icon: const Icon(Icons.translate_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (int value) => setState(() => index = value),
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: s.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: s.services,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2_rounded),
              label: s.projects,
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_circle_outline_rounded),
              selectedIcon: const Icon(Icons.add_circle_rounded),
              label: s.request,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: s.account,
            ),
          ],
        ),
      ),
    );
  }
}
