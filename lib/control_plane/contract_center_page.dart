import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/evento_theme.dart';

class EventoContractCenterPage extends StatefulWidget {
  const EventoContractCenterPage({super.key, this.arabic = true});

  final bool arabic;

  @override
  State<EventoContractCenterPage> createState() => _EventoContractCenterPageState();
}

class _EventoContractCenterPageState extends State<EventoContractCenterPage> {
  bool _loading = true;
  bool _busy = false;
  String? _message;
  List<_ContractCandidate> _items = const [];

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_client.auth.currentUser == null) {
      setState(() {
        _loading = false;
        _message = widget.arabic
            ? 'تسجيل الدخول إلى حساب EVENTO مطلوب.'
            : 'Sign in to your EVENTO account first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final requests = (await _client
              .from('project_requests')
              .select('id,request_code,title,status'))
          .cast<Map<String, dynamic>>();
      final workflows = (await _client
              .from('project_workflows')
              .select('request_id,current_stage'))
          .cast<Map<String, dynamic>>();
      final quotes = (await _client
              .from('project_quotes')
              .select('id,request_id,quote_code,status,total_aed'))
          .cast<Map<String, dynamic>>();
      final contracts = (await _client
              .from('project_contract_versions')
              .select(
                'id,contract_code,request_id,quote_id,version_number,status,terms_version,legal_review_status,legal_reviewed_at,legal_review_note,valid_until,created_at',
              )
              .order('version_number', ascending: false))
          .cast<Map<String, dynamic>>();

      final flowByRequest = <String, Map<String, dynamic>>{
        for (final row in workflows) row['request_id'] as String: row,
      };
      final quoteByRequest = <String, Map<String, dynamic>>{
        for (final row in quotes) row['request_id'] as String: row,
      };
      final contractByRequest = <String, Map<String, dynamic>>{};
      for (final row in contracts) {
        final requestId = row['request_id'] as String;
        contractByRequest.putIfAbsent(requestId, () => row);
      }

      final next = <_ContractCandidate>[];
      for (final request in requests) {
        final requestId = request['id'] as String;
        final flow = flowByRequest[requestId];
        final quote = quoteByRequest[requestId];
        if (flow == null || quote == null) continue;
        final stage = flow['current_stage']?.toString() ?? '';
        if (!{
          'quote_approved',
          'contract_sent',
          'contract_approved',
          'payment_verified',
          'build_queue',
        }.contains(stage)) {
          continue;
        }
        next.add(
          _ContractCandidate(
            requestId: requestId,
            requestCode: request['request_code']?.toString() ?? '',
            title: request['title']?.toString() ?? '',
            stage: stage,
            quote: quote,
            contract: contractByRequest[requestId],
          ),
        );
      }

      if (!mounted) return;
      setState(() => _items = next);
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createDraft(_ContractCandidate item) async {
    final terms = TextEditingController(text: 'terms-2026.08');
    final sow = TextEditingController(
      text: widget.arabic ? 'تنفيذ النطاق المعتمد للمشروع.' : 'Deliver the approved project scope.',
    );
    final deliverables = TextEditingController(
      text: widget.arabic ? 'الكود المصدري\nنسخة المعاينة\nوثائق التسليم' : 'Source code\nPreview build\nHandoff documentation',
    );
    final criteria = TextEditingController(
      text: widget.arabic ? 'نجاح الاختبارات\nاعتماد المعاينة' : 'Tests pass\nPreview approved',
    );
    final renderedAr = TextEditingController(
      text: 'مسودة عقد EVENTO مرتبطة بعرض السعر المقبول. يجب مراجعة هذه الشروط ونطاق العمل والتسليمات ومعايير القبول قبل اعتماد النسخة للاستخدام وإرسالها إلى العميل.',
    );
    final renderedEn = TextEditingController(
      text: 'EVENTO contract draft bound to the accepted quotation. Review these terms, scope, deliverables, and acceptance criteria before approving this version for customer use.',
    );

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Directionality(
          textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.arabic ? 'إنشاء مسودة عقد' : 'Create contract draft',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text('${item.requestCode} • ${item.title}'),
                const SizedBox(height: 14),
                TextField(
                  controller: terms,
                  decoration: InputDecoration(
                    labelText: widget.arabic ? 'نسخة الشروط' : 'Terms version',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sow,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: widget.arabic ? 'نطاق العمل' : 'Statement of work',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deliverables,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: widget.arabic ? 'التسليمات — سطر لكل عنصر' : 'Deliverables — one per line',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: criteria,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: widget.arabic ? 'معايير القبول — سطر لكل عنصر' : 'Acceptance criteria — one per line',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: renderedAr,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Arabic contract text'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: renderedEn,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'English contract text'),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(widget.arabic ? 'حفظ كمسودة تحتاج مراجعة' : 'Save as review-required draft'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) {
      terms.dispose();
      sow.dispose();
      deliverables.dispose();
      criteria.dispose();
      renderedAr.dispose();
      renderedEn.dispose();
      return;
    }

    final body = <String, dynamic>{
      'action': 'create_draft',
      'quote_id': item.quote['id'],
      'terms_version': terms.text.trim(),
      'statement_of_work': _lines(sow.text),
      'deliverables': _lines(deliverables.text),
      'acceptance_criteria': _lines(criteria.text),
      'rendered_terms_ar': renderedAr.text.trim(),
      'rendered_terms_en': renderedEn.text.trim(),
    };

    terms.dispose();
    sow.dispose();
    deliverables.dispose();
    criteria.dispose();
    renderedAr.dispose();
    renderedEn.dispose();

    await _invoke(
      body: body,
      success: widget.arabic
          ? 'تم إنشاء مسودة العقد. لا يمكن إرسالها قبل تسجيل مراجعة صريحة.'
          : 'Contract draft created. It cannot be sent until explicit review is recorded.',
    );
  }

  Future<void> _approveForUse(_ContractCandidate item) async {
    final contractId = item.contract?['id']?.toString();
    if (contractId == null) return;
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.arabic ? 'اعتماد العقد للاستخدام' : 'Approve contract for use'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.arabic
                  ? 'لا تعتمد النسخة إلا بعد مراجعة الشروط والنطاق والتسليمات ومعايير القبول. سيتم حفظ هويتك ووقت المراجعة والملاحظة.'
                  : 'Approve only after reviewing terms, scope, deliverables, and acceptance criteria. Your identity, timestamp, and review note will be recorded.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: widget.arabic ? 'ملاحظة المراجعة — 20 حرفًا على الأقل' : 'Review note — at least 20 characters',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.arabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.arabic ? 'تسجيل الاعتماد' : 'Record approval'),
          ),
        ],
      ),
    );
    final reviewNote = note.text.trim();
    note.dispose();
    if (confirmed != true) return;
    if (reviewNote.length < 20) {
      setState(() => _message = widget.arabic
          ? 'ملاحظة المراجعة يجب أن تكون 20 حرفًا على الأقل.'
          : 'The review note must be at least 20 characters.');
      return;
    }
    await _invoke(
      body: {
        'action': 'approve_for_use',
        'contract_version_id': contractId,
        'review_note': reviewNote,
      },
      success: widget.arabic
          ? 'تم تسجيل مراجعة النسخة واعتمادها للاستخدام.'
          : 'Review evidence recorded and the version is approved for use.',
    );
  }

  Future<void> _send(_ContractCandidate item) async {
    final contractId = item.contract?['id']?.toString();
    if (contractId == null) return;
    await _invoke(
      body: {'action': 'send', 'contract_version_id': contractId},
      success: widget.arabic
          ? 'تم إرسال نسخة العقد المراجعة إلى العميل.'
          : 'Reviewed contract version sent to the customer.',
    );
  }

  Future<void> _invoke({
    required Map<String, dynamic> body,
    required String success,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final response = await _client.functions.invoke('contract-action', body: body);
      if (response.status < 200 || response.status >= 300) {
        throw Exception(response.data);
      }
      await _load();
      if (mounted) setState(() => _message = success);
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.arabic ? 'مركز العقود' : 'Contract Center'),
          actions: [
            IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            children: [
              _ContractHero(arabic: widget.arabic),
              if (_loading || _busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: const TextStyle(color: EventoColors.gold)),
              ],
              const SizedBox(height: 16),
              if (!_loading && _items.isEmpty)
                _ContractInfo(
                  title: widget.arabic ? 'لا توجد عقود جاهزة' : 'No contract-ready projects',
                  text: widget.arabic
                      ? 'يظهر المشروع هنا بعد قبول العميل لعرض السعر.'
                      : 'A project appears here after the customer accepts the quotation.',
                )
              else
                for (final item in _items)
                  _ContractCard(
                    arabic: widget.arabic,
                    item: item,
                    busy: _busy,
                    onCreate: () => _createDraft(item),
                    onApprove: () => _approveForUse(item),
                    onSend: () => _send(item),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  static List<String> _lines(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

class _ContractHero extends StatelessWidget {
  const _ContractHero({required this.arabic});

  final bool arabic;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EventoColors.panelSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EventoColors.cyan.withValues(alpha: 0.35)),
        ),
        child: Text(
          arabic
              ? 'العقد مرحلة مستقلة بين السعر والدفع: أنشئ المسودة، راجعها، سجّل دليل المراجعة، ثم أرسل النسخة للعميل. لا يستطيع العميل أو Agent اعتماد عقد داخلي أو بدء الدفع قبل هذه البوابة.'
              : 'Contract is a separate gate between quotation and payment: draft it, review it, record review evidence, then send the version to the customer. Customers and agents cannot approve an internal draft or start payment before this gate.',
        ),
      );
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.arabic,
    required this.item,
    required this.busy,
    required this.onCreate,
    required this.onApprove,
    required this.onSend,
  });

  final bool arabic;
  final _ContractCandidate item;
  final bool busy;
  final VoidCallback onCreate;
  final VoidCallback onApprove;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final contract = item.contract;
    final status = contract?['status']?.toString();
    final review = contract?['legal_review_status']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${item.requestCode} • ${item.quote['quote_code']}'),
            const SizedBox(height: 8),
            Text('${arabic ? 'المرحلة' : 'Stage'}: ${item.stage}'),
            Text('${arabic ? 'قيمة العرض' : 'Quote value'}: AED ${item.quote['total_aed']}'),
            const SizedBox(height: 12),
            if (contract == null)
              FilledButton.icon(
                onPressed: busy ? null : onCreate,
                icon: const Icon(Icons.note_add_outlined),
                label: Text(arabic ? 'إنشاء مسودة عقد' : 'Create contract draft'),
              )
            else ...[
              Text('${contract['contract_code']} • v${contract['version_number']}'),
              Text('${arabic ? 'الحالة' : 'Status'}: $status'),
              Text('${arabic ? 'المراجعة' : 'Review'}: $review'),
              if (review == 'required' && status == 'draft') ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(arabic ? 'تسجيل مراجعة واعتماد النسخة' : 'Record review and approve version'),
                ),
              ],
              if (review == 'approved_for_use' && status == 'draft') ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: busy ? null : onSend,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(arabic ? 'إرسال النسخة للعميل' : 'Send version to customer'),
                ),
              ],
              if (status == 'sent')
                _ContractInfo(
                  title: arabic ? 'بانتظار العميل' : 'Waiting for customer',
                  text: arabic
                      ? 'لا يبدأ الدفع قبل قبول العميل لهذه النسخة.'
                      : 'Payment cannot start until the customer accepts this version.',
                ),
              if (status == 'accepted')
                _ContractInfo(
                  title: arabic ? 'العقد مقبول' : 'Contract accepted',
                  text: arabic
                      ? 'يمكن الآن الانتقال إلى بوابة الدفع الموثّق.'
                      : 'The verified payment gate may now begin.',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContractInfo extends StatelessWidget {
  const _ContractInfo({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EventoColors.cyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(text),
          ],
        ),
      );
}

class _ContractCandidate {
  const _ContractCandidate({
    required this.requestId,
    required this.requestCode,
    required this.title,
    required this.stage,
    required this.quote,
    required this.contract,
  });

  final String requestId;
  final String requestCode;
  final String title;
  final String stage;
  final Map<String, dynamic> quote;
  final Map<String, dynamic>? contract;
}
