import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var liveConfigured = false;
  if (_supabaseUrl.isNotEmpty && _supabasePublishableKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabasePublishableKey,
      );
      liveConfigured = true;
    } catch (_) {
      liveConfigured = false;
    }
  }
  runApp(EventoApp(liveConfigured: liveConfigured));
}

class EventoApp extends StatefulWidget {
  const EventoApp({super.key, required this.liveConfigured});

  final bool liveConfigured;

  @override
  State<EventoApp> createState() => _EventoAppState();
}

class _EventoAppState extends State<EventoApp> {
  bool _arabic = true;
  int _tab = 0;
  final List<EventoRequest> _localRequests = [];

  void _addLocal(EventoRequest request) {
    setState(() {
      _localRequests.insert(0, request);
      _tab = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF39A9FF),
      brightness: Brightness.dark,
      surface: const Color(0xFF0C1B2B),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EVENTO',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF06111F),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: Directionality(
        textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('EVENTO'),
            backgroundColor: const Color(0xFF06111F),
            actions: [
              _LiveIndicator(configured: widget.liveConfigured),
              IconButton(
                tooltip: _arabic ? 'English' : 'العربية',
                onPressed: () => setState(() => _arabic = !_arabic),
                icon: const Icon(Icons.translate),
              ),
            ],
          ),
          body: IndexedStack(
            index: _tab,
            children: [
              HomeScreen(
                arabic: _arabic,
                onRequest: () => setState(() => _tab = 3),
                onProjects: () => setState(() => _tab = 2),
              ),
              ServicesScreen(arabic: _arabic),
              ProjectsScreen(
                arabic: _arabic,
                onRequestProject: () => setState(() => _tab = 3),
              ),
              RequestScreen(
                arabic: _arabic,
                liveConfigured: widget.liveConfigured,
                onLocalRequest: _addLocal,
              ),
              AccountScreen(
                arabic: _arabic,
                liveConfigured: widget.liveConfigured,
                localRequests: _localRequests,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (value) => setState(() => _tab = value),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: _arabic ? 'الرئيسية' : 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome),
                label: _arabic ? 'الخدمات' : 'Services',
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view),
                label: _arabic ? 'المشاريع' : 'Projects',
              ),
              NavigationDestination(
                icon: const Icon(Icons.add_circle_outline),
                selectedIcon: const Icon(Icons.add_circle),
                label: _arabic ? 'طلب' : 'Request',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: _arabic ? 'حسابي' : 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: configured
                ? Colors.green.withValues(alpha: 0.16)
                : Colors.orange.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            configured ? 'LIVE' : 'DEMO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: configured ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.arabic,
    required this.onRequest,
    required this.onProjects,
  });

  final bool arabic;
  final VoidCallback onRequest;
  final VoidCallback onProjects;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0B2741), Color(0xFF0A1626)],
            ),
            border: Border.all(color: const Color(0xFF1C4465)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                arabic ? 'EVENTO PROJECT DEVELOPMENT' : 'EVENTO PROJECT DEVELOPMENT',
                style: const TextStyle(
                  color: Color(0xFF61E5FF),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                arabic
                    ? 'نحوّل فكرتك إلى منتج رقمي قابل للتجربة والبناء.'
                    : 'Turn your idea into a digital product you can test and build.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                arabic
                    ? 'حلّل فكرتك، راجع نطاق MVP، تابع الطلب، وجرب كل نسخة من هاتفك.'
                    : 'Analyze your idea, review the MVP scope, track the request, and test every build from your phone.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.bolt),
                label: Text(arabic ? 'حلّل فكرتي' : 'Analyze my idea'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onProjects,
                icon: const Icon(Icons.grid_view),
                label: Text(arabic ? 'استعرض المشاريع' : 'Browse projects'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle(arabic ? 'كيف تعمل EVENTO؟' : 'How EVENTO works'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StepCard('01', arabic ? 'الفكرة' : 'Idea', Icons.lightbulb_outline),
            _StepCard('02', arabic ? 'التحليل' : 'Analysis', Icons.psychology_outlined),
            _StepCard('03', arabic ? 'البناء' : 'Build', Icons.code),
            _StepCard('04', arabic ? 'التجربة' : 'Test', Icons.phone_android),
          ],
        ),
      ],
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, required this.arabic});

  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final services = [
      (Icons.web, arabic ? 'المواقع والمنصات' : 'Web & Platforms'),
      (Icons.phone_android, arabic ? 'تطبيقات الهاتف' : 'Mobile Apps'),
      (Icons.smart_toy_outlined, arabic ? 'حلول الذكاء الاصطناعي' : 'AI Solutions'),
      (Icons.sports_esports_outlined, arabic ? 'الألعاب والتجارب' : 'Games & Interactive'),
      (Icons.dashboard_customize_outlined, arabic ? 'لوحات التحكم' : 'Control Planes'),
      (Icons.cloud_outlined, arabic ? 'البنية السحابية والأتمتة' : 'Cloud & Automation'),
    ];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _SectionTitle(arabic ? 'خدمات EVENTO' : 'EVENTO Services'),
        const SizedBox(height: 12),
        for (final service in services)
          Card(
            child: ListTile(
              leading: Icon(service.$1, color: const Color(0xFF61E5FF)),
              title: Text(service.$2),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}

class ProjectInfo {
  const ProjectInfo(this.name, this.category, this.status);
  final String name;
  final String category;
  final String status;
}

const _featuredProjects = <ProjectInfo>[
  ProjectInfo('EVEX Lab', 'Health / AI', 'Active'),
  ProjectInfo('EVEX Coach', 'Health / AI', 'In development'),
  ProjectInfo('EVEX Fit', 'Fitness', 'In development'),
  ProjectInfo('AithenaX', 'FinTech / AI', 'In development'),
  ProjectInfo('CAMELEVEX', 'Knowledge / Desert Civilization', 'In development'),
  ProjectInfo('TheBacktrove', 'Digital Commerce', 'In development'),
  ProjectInfo('SMART OASIS UAE', 'Smart Infrastructure', 'Concept'),
  ProjectInfo('Smart Auction Signage', 'GovTech', 'Concept'),
  ProjectInfo('Al Dhafra Urban Vision', 'Urban Innovation', 'Concept'),
  ProjectInfo('Al Dhafra Health Innovation', 'Health Innovation', 'Concept'),
  ProjectInfo('Falaj Al-Dhill', 'Home / Landscape', 'Design'),
  ProjectInfo('Desert MMORPG', 'Game', 'Concept'),
  ProjectInfo('Al-Andalus Action Game', 'Game', 'Concept'),
  ProjectInfo('Police vs Criminals', 'Game', 'Concept'),
  ProjectInfo('Middle East Survival Adventure', 'Game / VR', 'Concept'),
];

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({
    super.key,
    required this.arabic,
    required this.onRequestProject,
  });

  final bool arabic;
  final VoidCallback onRequestProject;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _featuredProjects.where((project) {
      final q = _query.toLowerCase().trim();
      return q.isEmpty ||
          project.name.toLowerCase().contains(q) ||
          project.category.toLowerCase().contains(q) ||
          project.status.toLowerCase().contains(q);
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _SectionTitle(widget.arabic ? 'مشاريع EVENTO' : 'EVENTO Projects'),
        const SizedBox(height: 8),
        Text(
          widget.arabic
              ? 'هذه قناة Bootstrap للهاتف. تتم مزامنة السجل الرئيسي الكامل تدريجيًا دون كشف المشاريع الداخلية.'
              : 'This is the phone bootstrap catalog. The full master registry is synced progressively without exposing internal projects.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: widget.arabic ? 'ابحث عن مشروع أو مجال' : 'Search project or category',
          ),
        ),
        const SizedBox(height: 12),
        for (final project in filtered)
          Card(
            child: ListTile(
              title: Text(project.name),
              subtitle: Text('${project.category} • ${project.status}'),
              trailing: IconButton(
                tooltip: widget.arabic ? 'ابدأ مشروعًا مشابهًا' : 'Request similar project',
                onPressed: widget.onRequestProject,
                icon: const Icon(Icons.arrow_circle_right_outlined),
              ),
            ),
          ),
      ],
    );
  }
}

class EventoRequest {
  const EventoRequest({
    required this.code,
    required this.title,
    required this.status,
    required this.summary,
    required this.createdAt,
  });

  final String code;
  final String title;
  final String status;
  final String summary;
  final DateTime createdAt;
}

class RequestScreen extends StatefulWidget {
  const RequestScreen({
    super.key,
    required this.arabic,
    required this.liveConfigured,
    required this.onLocalRequest,
  });

  final bool arabic;
  final bool liveConfigured;
  final ValueChanged<EventoRequest> onLocalRequest;

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _details = TextEditingController();
  String _type = 'mobile';
  bool _busy = false;
  String? _result;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _result = null;
    });

    final localAnalysis = _analyzeIdea(_details.text, widget.arabic);
    if (widget.liveConfigured && Supabase.instance.client.auth.currentUser != null) {
      try {
        final client = Supabase.instance.client;
        final created = await client
            .from('project_requests')
            .insert({
              'project_type': _type,
              'title': _title.text.trim(),
              'details': _details.text.trim(),
            })
            .select('id,request_code,status,created_at')
            .single();
        try {
          await client.functions.invoke(
            'analyze-request',
            body: {'request_id': created['id']},
          );
        } catch (_) {
          // The request remains safely stored even if server analysis is delayed.
        }
        if (!mounted) return;
        setState(() {
          _result = widget.arabic
              ? 'تم حفظ الطلب ${created['request_code']} في EVENTO Live.\n$localAnalysis'
              : 'Request ${created['request_code']} saved to EVENTO Live.\n$localAnalysis';
        });
      } catch (error) {
        if (!mounted) return;
        _createLocal(localAnalysis, fallback: true);
      }
    } else {
      _createLocal(localAnalysis);
    }

    if (mounted) setState(() => _busy = false);
  }

  void _createLocal(String analysis, {bool fallback = false}) {
    final now = DateTime.now();
    final random = Random().nextInt(899999) + 100000;
    final code = 'EVT-${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$random';
    final request = EventoRequest(
      code: code,
      title: _title.text.trim(),
      status: fallback ? 'offline-fallback' : 'demo-analyzed',
      summary: analysis,
      createdAt: now,
    );
    widget.onLocalRequest(request);
    setState(() {
      _result = widget.arabic
          ? '${fallback ? 'تعذر الوصول للخادم؛ حُفظت نسخة محلية.' : 'تم التحليل التجريبي.'}\n$code\n$analysis'
          : '${fallback ? 'Server unavailable; a local fallback was saved.' : 'Demo analysis complete.'}\n$code\n$analysis';
    });
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      ('mobile', widget.arabic ? 'تطبيق' : 'Mobile'),
      ('web', widget.arabic ? 'موقع' : 'Web'),
      ('ai', widget.arabic ? 'ذكاء اصطناعي' : 'AI'),
      ('game', widget.arabic ? 'لعبة' : 'Game'),
    ];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _SectionTitle(widget.arabic ? 'حلّل فكرة مشروعك' : 'Analyze your project idea'),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final type in types)
                    ChoiceChip(
                      label: Text(type.$2),
                      selected: _type == type.$1,
                      onSelected: (_) => setState(() => _type = type.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: widget.arabic ? 'اسم الفكرة' : 'Idea title',
                ),
                validator: (value) => (value ?? '').trim().length < 3
                    ? (widget.arabic ? 'اكتب اسمًا أوضح' : 'Enter a clearer title')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _details,
                minLines: 6,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: widget.arabic ? 'اشرح ما تريد بناءه' : 'Describe what you want to build',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().length < 20
                    ? (widget.arabic ? 'أضف تفاصيل أكثر للتحليل' : 'Add more detail for analysis')
                    : null,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(widget.arabic ? 'حلّل وأرسل' : 'Analyze & submit'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_result!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _analyzeIdea(String details, bool arabic) {
  final text = details.toLowerCase();
  final capabilities = <String>[];
  if (text.contains('login') || text.contains('تسجيل') || text.contains('حساب')) {
    capabilities.add(arabic ? 'تسجيل دخول وحسابات' : 'Authentication & accounts');
  }
  if (text.contains('pay') || text.contains('دفع') || text.contains('اشتراك')) {
    capabilities.add(arabic ? 'دفع/اشتراكات' : 'Payments/subscriptions');
  }
  if (text.contains('ai') || text.contains('ذكاء') || text.contains('تحليل')) {
    capabilities.add(arabic ? 'ذكاء اصطناعي وتحليل' : 'AI & analysis');
  }
  if (text.contains('admin') || text.contains('لوحة') || text.contains('إدارة')) {
    capabilities.add(arabic ? 'لوحة إدارة' : 'Admin dashboard');
  }
  if (text.contains('notification') || text.contains('تنبيه') || text.contains('إشعار')) {
    capabilities.add(arabic ? 'تنبيهات وإشعارات' : 'Notifications');
  }
  if (capabilities.isEmpty) {
    capabilities.add(arabic ? 'تجربة مستخدم أساسية + بيانات + تتبع' : 'Core UX + data + tracking');
  }
  final complexity = capabilities.length >= 4
      ? (arabic ? 'متقدم' : 'Advanced')
      : capabilities.length >= 2
          ? (arabic ? 'متوسط' : 'Medium')
          : (arabic ? 'مبدئي' : 'Starter');
  final capText = capabilities.join(' • ');
  return arabic
      ? 'التعقيد: $complexity\nالمتطلبات المكتشفة: $capText\nMVP: تدفق رئيسي واحد، حساب/بيانات عند الحاجة، قياس، واختبار على الهاتف.'
      : 'Complexity: $complexity\nDetected capabilities: $capText\nMVP: one core journey, account/data when needed, measurement, and phone testing.';
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.arabic,
    required this.liveConfigured,
    required this.localRequests,
  });

  final bool arabic;
  final bool liveConfigured;
  final List<EventoRequest> localRequests;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!widget.liveConfigured || _email.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _email.text.trim(),
        shouldCreateUser: true,
      );
      setState(() {
        _otpSent = true;
        _message = widget.arabic
            ? 'أرسلنا رمز الدخول إلى بريدك.'
            : 'A sign-in code was sent to your email.';
      });
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _email.text.trim(),
        token: _otp.text.trim(),
        type: OtpType.email,
      );
      setState(() {
        _message = widget.arabic ? 'تم تسجيل الدخول.' : 'Signed in.';
      });
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.liveConfigured ? Supabase.instance.client : null;
    final signedIn = client?.auth.currentUser != null;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _SectionTitle(widget.arabic ? 'حساب EVENTO' : 'EVENTO Account'),
        const SizedBox(height: 12),
        if (!widget.liveConfigured)
          const Card(
            child: ListTile(
              leading: Icon(Icons.offline_bolt),
              title: Text('Demo mode'),
              subtitle: Text('Supabase live configuration is not present in this build.'),
            ),
          )
        else if (!signedIn) ...[
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: widget.arabic ? 'البريد الإلكتروني' : 'Email',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _busy ? null : _sendOtp,
            child: Text(widget.arabic ? 'إرسال رمز الدخول' : 'Send sign-in code'),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.arabic ? 'رمز OTP' : 'OTP code',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy ? null : _verifyOtp,
              child: Text(widget.arabic ? 'تأكيد' : 'Verify'),
            ),
          ],
        ] else ...[
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(client!.auth.currentUser?.email ?? 'EVENTO user'),
              subtitle: Text(widget.arabic ? 'متصل بـ EVENTO Live' : 'Connected to EVENTO Live'),
              trailing: IconButton(
                tooltip: widget.arabic ? 'تسجيل الخروج' : 'Sign out',
                onPressed: () async {
                  await client.auth.signOut();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.logout),
              ),
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!),
        ],
        const SizedBox(height: 20),
        _SectionTitle(widget.arabic ? 'طلبات هذا الجهاز' : 'Requests on this device'),
        const SizedBox(height: 8),
        if (widget.localRequests.isEmpty)
          Text(widget.arabic ? 'لا توجد طلبات محلية بعد.' : 'No local requests yet.')
        else
          for (final request in widget.localRequests)
            Card(
              child: ListTile(
                title: Text(request.title),
                subtitle: Text('${request.code}\n${request.status}\n${request.summary}'),
                isThreeLine: true,
              ),
            ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard(this.number, this.label, this.icon);

  final String number;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1B2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF17334C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF61E5FF)),
          const SizedBox(height: 12),
          Text(number, style: const TextStyle(color: Color(0xFFFFC857))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
