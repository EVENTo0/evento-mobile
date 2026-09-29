import 'dart:async';

import 'package:flutter/material.dart';

import 'one_member_controller.dart';

class OneMemberApp extends StatefulWidget {
  const OneMemberApp({super.key, required this.controller});
  final OneMemberController controller;
  @override
  State<OneMemberApp> createState() => _OneMemberAppState();
}

class _OneMemberAppState extends State<OneMemberApp>
    with WidgetsBindingObserver {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _arabic = true;
  int _tab = 0;
  bool _obscured = false;
  OneMemberController get model => widget.controller;
  String tr(String ar, String en) => _arabic ? ar : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hide sensitive lists in the app switcher; revalidate current memberships on resume.
    if (!mounted) return;
    if (state != AppLifecycleState.resumed) {
      setState(() => _obscured = true);
    } else {
      if (model.context != null) {
        unawaited(model.refresh(invalidatePending: true));
      }
      setState(() => _obscured = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _email.dispose();
    _password.dispose();
    model.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    _password.clear();
    if (!email.contains('@') || password.isEmpty) return;
    await model.signIn(email, password);
    if (model.context != null) _email.clear();
  }

  String errorMessage(String? code) => switch (code) {
    'session_expired' => tr(
      'انتهت الجلسة. سجّل الدخول مجددًا.',
      'Your session ended. Sign in again.',
    ),
    'login_failed' => tr(
      'تعذر تسجيل الدخول. تحقق من البيانات والاتصال.',
      'Sign-in failed. Check your details and connection.',
    ),
    'access_denied' => tr(
      'الوصول غير متاح لهذه المؤسسة. حدّث المؤسسات أو سجّل الخروج.',
      'Access is unavailable for this organization. Refresh memberships or sign out.',
    ),
    'unavailable' => tr(
      'تعذر تحميل البيانات الآن. حاول مرة أخرى.',
      'Data is unavailable right now. Try again.',
    ),
    _ => '',
  };

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'EVENTO ONE',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF39A9FF),
      scaffoldBackgroundColor: const Color(0xFF06111F),
    ),
    home: AnimatedBuilder(
      animation: model,
      builder: (context, _) => Directionality(
        textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('EVENTO ONE'),
            actions: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Text('TEST')),
              ),
              IconButton(
                key: const Key('one-language'),
                tooltip: _arabic ? 'English' : 'العربية',
                onPressed: () => setState(() => _arabic = !_arabic),
                icon: const Icon(Icons.translate),
              ),
              if (model.context != null)
                IconButton(
                  key: const Key('one-logout'),
                  tooltip: tr('تسجيل الخروج', 'Sign out'),
                  onPressed: () {
                    _password.clear();
                    _email.clear();
                    unawaited(model.signOut());
                  },
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),
          body: _obscured
              ? const Center(child: Icon(Icons.lock_outline, size: 48))
              : SafeArea(
                  child: model.state == OneMemberState.disabled
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              tr(
                                'نسخة اختبار غير مفعّلة. سيتاح تسجيل الدخول بعد إعداد بيئة EVENTO ONE.',
                                'This test build is not activated. Sign-in becomes available after the EVENTO ONE environment is configured.',
                              ),
                              key: const Key('one-disabled'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : model.context == null
                      ? _loginView()
                      : _workspaceView(),
                ),
        ),
      ),
    ),
  );

  Widget _loginView() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('مساحة أعضاء المؤسسة', 'Organization member workspace'),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              tr(
                'للمالك وفريق العمل المخوّل. القراءة فقط في هذه النسخة.',
                'For owners and authorized team members. This build is read only.',
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('one-email'),
              controller: _email,
              enabled: !model.busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: tr('البريد الإلكتروني', 'Email'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('one-password'),
              controller: _password,
              enabled: !model.busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: tr('كلمة المرور', 'Password'),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 16),
            if (model.message != null)
              Text(
                errorMessage(model.message),
                key: const Key('one-error'),
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            if (model.busy)
              const Center(
                child: CircularProgressIndicator(key: Key('one-loading')),
              )
            else
              FilledButton(
                key: const Key('one-sign-in'),
                onPressed: _login,
                child: Text(tr('تسجيل الدخول', 'Sign in')),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _workspaceView() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                key: const Key('one-organizations'),
                isExpanded: true,
                value: model.organization?.id,
                hint: Text(tr('المؤسسة', 'Organization')),
                items: model.context!.organizations
                    .map(
                      (org) => DropdownMenuItem(
                        value: org.id,
                        child: Text(
                          org.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) {
                    setState(() => _tab = 0);
                    unawaited(model.selectOrganization(id));
                  }
                },
              ),
            ),
            IconButton(
              key: const Key('one-refresh'),
              tooltip: tr('تحديث', 'Refresh'),
              onPressed: model.busy ? null : model.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      if (model.organization != null)
        Text('${model.organization!.role} · ${tr('قراءة فقط', 'Read only')}'),
      if (model.message != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            errorMessage(model.message),
            key: const Key('one-error'),
            style: const TextStyle(color: Colors.orangeAccent),
          ),
        ),
      if (model.context!.organizations.isEmpty)
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                tr(
                  'لا توجد عضوية نشطة. تواصل مع مسؤول مؤسستك.',
                  'No active organization membership. Contact your organization administrator.',
                ),
                key: const Key('one-no-membership'),
              ),
            ),
          ),
        )
      else if (model.busy)
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(key: Key('one-loading')),
          ),
        )
      else if (model.data == null)
        Expanded(
          child: Center(
            child: FilledButton(
              key: const Key('one-retry'),
              onPressed: model.refresh,
              child: Text(tr('إعادة المحاولة', 'Retry')),
            ),
          ),
        )
      else
        Expanded(
          child: Column(
            children: [
              NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (value) => setState(() => _tab = value),
                destinations: [
                  NavigationDestination(
                    key: const Key('one-bookings-tab'),
                    icon: const Icon(Icons.calendar_month),
                    label: tr('الحجوزات', 'Bookings'),
                  ),
                  NavigationDestination(
                    key: const Key('one-quotes-tab'),
                    icon: const Icon(Icons.description_outlined),
                    label: tr('العروض', 'Quotations'),
                  ),
                  NavigationDestination(
                    key: const Key('one-invoices-tab'),
                    icon: const Icon(Icons.receipt_long),
                    label: tr('الفواتير', 'Invoices'),
                  ),
                ],
              ),
              Expanded(child: _records()),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  tr(
                    'أحدث 50 سجلًا كحد أقصى. العرض ليس تصديرًا كاملًا.',
                    'Up to 50 records. This view is not a complete export.',
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  String _money(int minor, String currency) =>
      '$currency ${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
  Widget _records() {
    final data = model.data!;
    final List<Widget> cards;
    if (_tab == 0) {
      cards = data.bookings
          .map(
            (row) => ListTile(
              key: ValueKey(row.id),
              title: Text(
                '${row.scheduledStart.toIso8601String().replaceFirst('T', ' ').substring(0, 16)} UTC',
              ),
              subtitle: Text(row.status),
              leading: const Icon(Icons.event),
            ),
          )
          .toList();
    } else if (_tab == 1) {
      cards = data.quotations
          .map(
            (row) => ListTile(
              key: ValueKey(row.id),
              title: Text(row.quoteNumber),
              subtitle: Text(
                '${row.status} · ${_money(row.totalMinor, row.currency)}',
              ),
              leading: const Icon(Icons.description),
            ),
          )
          .toList();
    } else {
      cards = data.invoices
          .map(
            (row) => ListTile(
              key: ValueKey(row.id),
              title: Text(row.invoiceNumber),
              subtitle: Text(
                '${row.status}\n${tr('الإجمالي', 'Total')}: ${_money(row.totalMinor, row.currency)}\n'
                '${tr('المتبقي', 'Due')}: ${_money(row.amountDueMinor, row.currency)}',
              ),
              isThreeLine: true,
              leading: const Icon(Icons.receipt_long),
            ),
          )
          .toList();
    }
    return cards.isEmpty
        ? Center(
            child: Text(
              tr('لا توجد سجلات.', 'No records.'),
              key: const Key('one-empty'),
            ),
          )
        : ListView(children: cards);
  }
}
