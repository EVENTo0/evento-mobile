import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/evento_theme.dart';
import 'data/repositories/project_request_repository.dart';
import 'domain/project_contract.dart';
import 'domain/project_quote.dart';
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
                MaterialPageRoute<void>(
                  builder: (_) => const _WorkflowCenterPage(),
                ),
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
  final Map<String, ProjectWorkflowRecord?> workflows =
      <String, ProjectWorkflowRecord?>{};
  final Map<String, ProjectQuoteRecord?> quotes = <String, ProjectQuoteRecord?>{};
  final Map<String, ProjectContractVersionRecord?> contracts =
      <String, ProjectContractVersionRecord?>{};

  SupabaseProjectRequestRepository get repository =>
      SupabaseProjectRequestRepository(Supabase.instance.client);

  User? get currentUser => Supabase.instance.client.auth.currentUser;
  bool get signedIn => currentUser != null;
  bool get anonymous => currentUser?.isAnonymous ?? true;

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
      final rows = await repository.listMine();
      final nextWorkflows = <String, ProjectWorkflowRecord?>{};
      final nextQuotes = <String, ProjectQuoteRecord?>{};
      final nextContracts = <String, ProjectContractVersionRecord?>{};
      for (final row in rows) {
        nextWorkflows[row.id] = await repository.getWorkflow(row.id);
        if (!anonymous) {
          nextQuotes[row.id] = await repository.getQuote(row.id);
          nextContracts[row.id] = await repository.getContract(row.id);
        }
      }
      if (!mounted) return;
      setState(() {
        requests = rows;
        workflows
          ..clear()
          ..addAll(nextWorkflows);
        quotes
          ..clear()
          ..addAll(nextQuotes);
        contracts
          ..clear()
          ..addAll(nextContracts);
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

  Future<void> _acceptQuote(ProjectQuoteRecord quote) async {
    await _runTransition(
      () => repository.acceptQuote(quote.id),
      arabic
          ? 'تم قبول عرض السعر. العقد المراجع هو البوابة التالية.'
          : 'Quote accepted. The reviewed contract is the next gate.',
    );
  }

  Future<void> _acceptContract(ProjectContractVersionRecord contract) async {
    await _runTransition(
      () => repository.acceptContract(contract.id),
      arabic
          ? 'تم قبول نسخة العقد المراجعة. الدفع هو البوابة التالية.'
          : 'Reviewed contract accepted. Payment is the next gate.',
    );
  }

  Future<void> _runTransition(
    Future<void> Function() action,
    String success,
  ) async {
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
          title: Text(
            arabic ? 'مركز تنفيذ المشاريع • RC6' : 'Project Workflow Center • RC6',
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () => setState(() => arabic = !arabic),
              icon: const Icon(Icons.translate),
            ),
            IconButton(
              onPressed: busy ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: <Widget>[
              _WorkflowIntro(arabic: arabic, anonymous: anonymous),
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
                      ? 'ارجع إلى حسابي وسجّل الدخول ثم افتح Workflow.'
                      : 'Return to Account, sign in, then reopen Workflow.',
                )
              else if (requests.isEmpty)
                _WorkflowInfo(
                  title: arabic ? 'لا توجد طلبات' : 'No requests',
                  text: arabic ? 'أنشئ طلب مشروع أولًا.' : 'Create a project request first.',
                )
              else
                for (final request in requests)
                  _WorkflowRequestCard(
                    arabic: arabic,
                    anonymous: anonymous,
                    request: request,
                    workflow: workflows[request.id],
                    quote: quotes[request.id],
                    contract: contracts[request.id],
                    busy: busy,
                    onStart: () => _start(request),
                    onApprove: () => _approve(request),
                    onAcceptQuote: quotes[request.id] == null
                        ? null
                        : () => _acceptQuote(quotes[request.id]!),
                    onAcceptContract: contracts[request.id] == null
                        ? null
                        : () => _acceptContract(contracts[request.id]!),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowIntro extends StatelessWidget {
  const _WorkflowIntro({required this.arabic, required this.anonymous});

  final bool arabic;
  final bool anonymous;

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
                  Text(
                    'SERVER-CONTROLLED',
                    style: TextStyle(
                      color: EventoColors.cyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                anonymous
                    ? (arabic
                        ? 'وضع التجربة يسمح بالفكرة والتحليل فقط. يلزم حساب موثّق قبل Workflow التجاري وعروض الأسعار.'
                        : 'Demo mode supports idea analysis only. A verified account is required before commercial workflow and quotations.')
                    : (arabic
                        ? 'المسار التجاري مضبوط خادميًا: نطاق → عرض سعر → عقد مراجع → دفع موثّق → إذن بشري بالتنفيذ → بناء.'
                        : 'The commercial path is server-controlled: scope → quote → reviewed contract → verified payment → human fulfillment authorization → build.'),
              ),
            ],
          ),
        ),
      );
}

class _WorkflowRequestCard extends StatelessWidget {
  const _WorkflowRequestCard({
    required this.arabic,
    required this.anonymous,
    required this.request,
    required this.workflow,
    required this.quote,
    required this.contract,
    required this.busy,
    required this.onStart,
    required this.onApprove,
    required this.onAcceptQuote,
    required this.onAcceptContract,
  });

  final bool arabic;
  final bool anonymous;
  final ProjectRequestRecord request;
  final ProjectWorkflowRecord? workflow;
  final ProjectQuoteRecord? quote;
  final ProjectContractVersionRecord? contract;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onApprove;
  final VoidCallback? onAcceptQuote;
  final VoidCallback? onAcceptContract;

  @override
  Widget build(BuildContext context) {
    final flow = workflow;
    final stage = flow?.currentStage;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              request.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              request.requestCode,
              style: const TextStyle(color: EventoColors.muted),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (flow?.progressPercent ?? 15) / 100),
            const SizedBox(height: 8),
            Text(
              flow == null
                  ? (arabic
                      ? 'اكتمل التحليل • جاهز لبدء Workflow'
                      : 'Analysis complete • ready to start workflow')
                  : '${flow.localizedStage(arabic)} • ${flow.progressPercent}%',
              style: const TextStyle(
                color: EventoColors.cyan,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (anonymous && request.status == ProjectRequestStatus.analyzed)
              _WorkflowInfo(
                title: arabic ? 'حساب موثّق مطلوب' : 'Verified account required',
                text: arabic
                    ? 'سجّل أو حوّل الحساب التجريبي إلى حساب دائم قبل الانتقال إلى المراحل التجارية.'
                    : 'Register or convert the demo account to a permanent account before commercial stages.',
              )
            else if (flow == null && request.status == ProjectRequestStatus.analyzed)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    arabic ? 'ابدأ مراجعة نطاق المشروع' : 'Start scope review',
                  ),
                ),
              )
            else if (stage == 'scope_review' ||
                request.status == ProjectRequestStatus.awaitingScope)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  icon: const Icon(Icons.approval_outlined),
                  label: Text(
                    arabic ? 'اعتمد نطاق المشروع' : 'Approve project scope',
                  ),
                ),
              )
            else if (stage == 'scope_approved')
              _WorkflowInfo(
                title: arabic ? 'النطاق معتمد' : 'Scope approved',
                text: arabic
                    ? 'EVENTO تراجع التسعير الآن. سيظهر عرض السعر هنا بعد إرساله.'
                    : 'EVENTO is preparing pricing. The quotation will appear here after it is sent.',
              )
            else if (stage == 'quote_draft')
              _WorkflowInfo(
                title: arabic ? 'عرض السعر قيد الإعداد' : 'Quote is being prepared',
                text: arabic
                    ? 'المسودة داخل EVENTO ولم تُرسل للعميل بعد.'
                    : 'The quotation is still an EVENTO internal draft.',
              )
            else if (stage == 'quote_sent')
              _QuoteApprovalCard(
                arabic: arabic,
                quote: quote,
                busy: busy,
                onAccept: onAcceptQuote,
              )
            else if (stage == 'quote_approved')
              _ContractWaitingCard(arabic: arabic, contract: contract)
            else if (stage == 'contract_sent')
              _ContractApprovalCard(
                arabic: arabic,
                contract: contract,
                busy: busy,
                onAccept: onAcceptContract,
              )
            else if (stage == 'contract_approved')
              _WorkflowInfo(
                title: arabic ? 'العقد مقبول' : 'Contract accepted',
                text: arabic
                    ? 'تم تثبيت العقد المراجع. الدفع هو البوابة التالية، ولا يبدأ البناء بمجرد العودة من صفحة Checkout.'
                    : 'The reviewed contract is fixed. Payment is next; returning from Checkout never starts the build by itself.',
              )
            else if (stage == 'payment_verified')
              _WorkflowInfo(
                title: arabic ? 'تم توثيق الدفع' : 'Payment verified',
                text: arabic
                    ? 'تحقق الخادم من الدفع. المشروع ما زال pending_payment حتى يعتمد مالك/مشغّل EVENTO بدء التنفيذ.'
                    : 'The server verified payment. The project remains pending_payment until an EVENTO owner/operator authorizes fulfillment.',
              )
            else if (stage == 'build_queue')
              _WorkflowInfo(
                title: arabic ? 'تم اعتماد بدء التنفيذ' : 'Fulfillment authorized',
                text: arabic
                    ? 'صدر إذن بشري بالتنفيذ وأصبح المشروع في قائمة البناء المصرّح بها.'
                    : 'Human fulfillment authorization was recorded and the project is now in the authorized build queue.',
              )
            else if (stage == null && request.status == ProjectRequestStatus.quoted)
              _QuoteApprovalCard(
                arabic: arabic,
                quote: quote,
                busy: busy,
                onAccept: onAcceptQuote,
              )
            else if (stage == null && request.status == ProjectRequestStatus.approved)
              _ContractWaitingCard(arabic: arabic, contract: contract),
          ],
        ),
      ),
    );
  }
}

class _QuoteApprovalCard extends StatelessWidget {
  const _QuoteApprovalCard({
    required this.arabic,
    required this.quote,
    required this.busy,
    required this.onAccept,
  });

  final bool arabic;
  final ProjectQuoteRecord? quote;
  final bool busy;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final value = quote;
    if (value == null) {
      return _WorkflowInfo(
        title: arabic ? 'جاري تحميل عرض السعر' : 'Loading quotation',
        text: arabic
            ? 'حدّث الصفحة بعد لحظات إذا استمرت هذه الحالة.'
            : 'Refresh the page if this state persists.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EventoColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EventoColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arabic ? 'عرض سعر EVENTO' : 'EVENTO quotation',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(value.quoteCode, style: const TextStyle(color: EventoColors.muted)),
          const SizedBox(height: 8),
          Text(
            'AED ${value.totalAed.toStringAsFixed(2)}',
            style: const TextStyle(
              color: EventoColors.gold,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          if (value.validUntil != null) ...[
            const SizedBox(height: 4),
            Text(
              '${arabic ? 'صالح حتى' : 'Valid until'}: ${value.validUntil!.toLocal()}',
              style: const TextStyle(color: EventoColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy || value.status != 'sent' ? null : onAccept,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(arabic ? 'أوافق على عرض السعر' : 'Accept quotation'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            arabic
                ? 'قبول العرض يثبت النسخة الحالية فقط؛ العقد المراجع هو البوابة التالية قبل الدفع.'
                : 'Accepting the quote fixes this version only; the reviewed contract is the next gate before payment.',
            style: const TextStyle(color: EventoColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ContractWaitingCard extends StatelessWidget {
  const _ContractWaitingCard({required this.arabic, required this.contract});

  final bool arabic;
  final ProjectContractVersionRecord? contract;

  @override
  Widget build(BuildContext context) {
    final value = contract;
    if (value == null) {
      return _WorkflowInfo(
        title: arabic ? 'العقد هو البوابة التالية' : 'Contract is the next gate',
        text: arabic
            ? 'قبل الدفع، تُعد EVENTO نسخة عقد مرتبطة بعرض السعر المقبول وتخضع للمراجعة ثم تُرسل إليك.'
            : 'Before payment, EVENTO prepares a contract version bound to the accepted quote, reviews it, then sends it to you.',
      );
    }
    if (value.status == 'draft') {
      return _WorkflowInfo(
        title: arabic ? 'العقد قيد المراجعة' : 'Contract under review',
        text: arabic
            ? 'نسخة العقد داخل EVENTO ولم تصبح قابلة لقبول العميل بعد.'
            : 'The contract version remains internal to EVENTO and is not yet customer-acceptable.',
      );
    }
    return _WorkflowInfo(
      title: arabic ? 'العقد جاهز للمراجعة' : 'Contract ready for review',
      text: arabic
          ? 'حدّث Workflow لعرض نسخة العقد المرسلة واعتمادها.'
          : 'Refresh Workflow to review and accept the sent contract version.',
    );
  }
}

class _ContractApprovalCard extends StatelessWidget {
  const _ContractApprovalCard({
    required this.arabic,
    required this.contract,
    required this.busy,
    required this.onAccept,
  });

  final bool arabic;
  final ProjectContractVersionRecord? contract;
  final bool busy;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final value = contract;
    if (value == null) {
      return _WorkflowInfo(
        title: arabic ? 'جاري تحميل العقد' : 'Loading contract',
        text: arabic
            ? 'حدّث الصفحة إذا استمرت هذه الحالة.'
            : 'Refresh if this state persists.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EventoColors.cyan.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EventoColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arabic ? 'عقد EVENTO المراجع' : 'Reviewed EVENTO contract',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.contractCode} • v${value.versionNumber} • ${value.termsVersion}',
            style: const TextStyle(color: EventoColors.muted),
          ),
          const SizedBox(height: 10),
          Text(
            arabic ? value.renderedTermsAr : (value.renderedTermsEn ?? value.renderedTermsAr),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
          if (value.deliverables.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              arabic ? 'التسليمات' : 'Deliverables',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            for (final item in value.deliverables)
              Text('• $item'),
          ],
          if (value.acceptanceCriteria.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              arabic ? 'معايير القبول' : 'Acceptance criteria',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            for (final item in value.acceptanceCriteria)
              Text('• $item'),
          ],
          const SizedBox(height: 10),
          Text(
            '${arabic ? 'المراجعة' : 'Review'}: ${value.legalReviewStatus}',
            style: const TextStyle(color: EventoColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy || !value.isAcceptable ? null : onAccept,
              icon: const Icon(Icons.gavel_outlined),
              label: Text(arabic ? 'أوافق على نسخة العقد' : 'Accept contract version'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            arabic
                ? 'قبول العقد لا يثبت الدفع ولا يبدأ التنفيذ. الدفع الموثّق ثم إذن EVENTO البشري بوابتان مستقلتان.'
                : 'Contract acceptance does not prove payment or start fulfillment. Verified payment and human EVENTO authorization remain separate gates.',
            style: const TextStyle(color: EventoColors.muted, fontSize: 12),
          ),
        ],
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
