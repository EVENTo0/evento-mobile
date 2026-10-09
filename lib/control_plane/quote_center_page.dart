import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/evento_theme.dart';

class EventoQuoteCenterPage extends StatefulWidget {
  const EventoQuoteCenterPage({super.key, this.arabic = true});

  final bool arabic;

  @override
  State<EventoQuoteCenterPage> createState() => _EventoQuoteCenterPageState();
}

class _EventoQuoteCenterPageState extends State<EventoQuoteCenterPage> {
  bool _loading = true;
  bool _busy = false;
  String? _message;
  List<_QuoteCandidate> _items = const [];

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
              .select('id,request_code,title,status,created_at'))
          .cast<Map<String, dynamic>>();
      final workflows = (await _client
              .from('project_workflows')
              .select('request_id,current_stage,estimated_price_aed,progress_percent'))
          .cast<Map<String, dynamic>>();
      final quotes = (await _client
              .from('project_quotes')
              .select('id,quote_code,request_id,status,total_aed,valid_until,sent_at,accepted_at'))
          .cast<Map<String, dynamic>>();

      final workflowsByRequest = <String, Map<String, dynamic>>{
        for (final row in workflows) row['request_id'] as String: row,
      };
      final quotesByRequest = <String, Map<String, dynamic>>{
        for (final row in quotes) row['request_id'] as String: row,
      };

      final next = <_QuoteCandidate>[];
      for (final request in requests) {
        final requestId = request['id'] as String;
        final flow = workflowsByRequest[requestId];
        if (flow == null) continue;
        final stage = flow['current_stage']?.toString() ?? '';
        if (!{'scope_approved', 'quote_draft', 'quote_sent', 'quote_approved'}
            .contains(stage)) {
          continue;
        }
        next.add(_QuoteCandidate(
          requestId: requestId,
          requestCode: request['request_code']?.toString() ?? '',
          title: request['title']?.toString() ?? '',
          requestStatus: request['status']?.toString() ?? '',
          stage: stage,
          quote: quotesByRequest[requestId],
        ));
      }

      if (!mounted) return;
      setState(() => _items = next);
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDraft(_QuoteCandidate item) async {
    final subtotal = TextEditingController(
      text: item.quote?['total_aed']?.toString() ?? '',
    );
    final discount = TextEditingController(text: '0');
    final tax = TextEditingController(text: '0');

    final result = await showModalBottomSheet<_QuoteDraftInput>(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.arabic ? 'إعداد عرض السعر' : 'Prepare quotation',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text('${item.requestCode} • ${item.title}'),
              const SizedBox(height: 16),
              TextField(
                controller: subtotal,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.arabic ? 'السعر الأساسي AED' : 'Subtotal AED',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.arabic ? 'الخصم AED' : 'Discount AED',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tax,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.arabic ? 'الضريبة AED' : 'Tax AED',
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  _QuoteDraftInput(
                    subtotal: subtotal.text.trim(),
                    discount: discount.text.trim(),
                    tax: tax.text.trim(),
                  ),
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.arabic ? 'حفظ Draft' : 'Save draft'),
              ),
            ],
          ),
        ),
      ),
    );

    subtotal.dispose();
    discount.dispose();
    tax.dispose();
    if (result == null) return;

    await _invoke(
      body: {
        'action': 'create_draft',
        'request_id': item.requestId,
        'subtotal_aed': result.subtotal,
        'discount_aed': result.discount.isEmpty ? '0' : result.discount,
        'tax_aed': result.tax.isEmpty ? '0' : result.tax,
        'pricing_breakdown': [
          {
            'item': 'EVENTO project delivery',
            'amount_aed': result.subtotal,
          }
        ],
      },
      success: widget.arabic
          ? 'تم حفظ عرض السعر كمسودة.'
          : 'Quotation draft saved.',
    );
  }

  Future<void> _sendQuote(_QuoteCandidate item) async {
    final quoteId = item.quote?['id']?.toString();
    if (quoteId == null || quoteId.isEmpty) return;
    await _invoke(
      body: {'action': 'send', 'quote_id': quoteId},
      success: widget.arabic
          ? 'تم إرسال عرض السعر للعميل.'
          : 'Quotation sent to the customer.',
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
      final response = await _client.functions.invoke('quote-action', body: body);
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
          title: Text(widget.arabic ? 'مركز عروض الأسعار' : 'Quote Center'),
          actions: [
            IconButton(
              onPressed: _busy ? null : _load,
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
              _QuoteHero(arabic: widget.arabic),
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
                _QuoteInfo(
                  title: widget.arabic ? 'لا توجد عروض جاهزة' : 'No quote-ready projects',
                  text: widget.arabic
                      ? 'يظهر المشروع هنا بعد اعتماد نطاقه من حساب عميل موثّق.'
                      : 'A project appears here after its scope is approved by a verified customer account.',
                )
              else
                for (final item in _items)
                  _QuoteCard(
                    arabic: widget.arabic,
                    item: item,
                    busy: _busy,
                    onDraft: () => _openDraft(item),
                    onSend: () => _sendQuote(item),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteHero extends StatelessWidget {
  const _QuoteHero({required this.arabic});

  final bool arabic;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EventoColors.panelSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EventoColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.request_quote_outlined, color: EventoColors.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                arabic
                    ? 'المالك أو الفريق المخوّل يراجع السعر ثم يرسل العرض. الذكاء الاصطناعي يمكنه اقتراح التسعير لاحقًا، لكنه لا يرسل السعر للعميل تلقائيًا.'
                    : 'Authorized EVENTO staff reviews pricing before sending. AI may suggest pricing later, but cannot send a customer quote automatically.',
              ),
            ),
          ],
        ),
      );
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.arabic,
    required this.item,
    required this.busy,
    required this.onDraft,
    required this.onSend,
  });

  final bool arabic;
  final _QuoteCandidate item;
  final bool busy;
  final VoidCallback onDraft;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final quote = item.quote;
    final status = quote?['status']?.toString();
    final total = quote?['total_aed'];
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
            Text(item.requestCode, style: const TextStyle(color: EventoColors.muted)),
            const SizedBox(height: 10),
            Text('${arabic ? 'المرحلة' : 'Stage'}: ${item.stage}'),
            if (status != null)
              Text('${arabic ? 'حالة العرض' : 'Quote status'}: $status'),
            if (total != null)
              Text(
                'AED ${total.toString()}',
                style: const TextStyle(
                  color: EventoColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 12),
            if (item.stage == 'scope_approved' || item.stage == 'quote_draft')
              FilledButton.icon(
                onPressed: busy ? null : onDraft,
                icon: const Icon(Icons.edit_note_outlined),
                label: Text(arabic ? 'إعداد / تعديل السعر' : 'Prepare / edit quote'),
              ),
            if (status == 'draft') ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : onSend,
                icon: const Icon(Icons.send_outlined),
                label: Text(arabic ? 'إرسال للعميل' : 'Send to customer'),
              ),
            ],
            if (status == 'sent')
              _QuoteInfo(
                title: arabic ? 'بانتظار العميل' : 'Waiting for customer',
                text: arabic
                    ? 'تم إرسال العرض. القبول يتم من حساب العميل الموثّق.'
                    : 'The quote was sent. Acceptance must come from the verified customer account.',
              ),
            if (status == 'accepted')
              _QuoteInfo(
                title: arabic ? 'تم قبول العرض' : 'Quote accepted',
                text: arabic
                    ? 'المشروع الآن عند بوابة الدفع قبل دخوله Build Queue الفعلي.'
                    : 'The project is now at the payment gate before the active build queue.',
              ),
          ],
        ),
      ),
    );
  }
}

class _QuoteInfo extends StatelessWidget {
  const _QuoteInfo({required this.title, required this.text});

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

class _QuoteCandidate {
  const _QuoteCandidate({
    required this.requestId,
    required this.requestCode,
    required this.title,
    required this.requestStatus,
    required this.stage,
    this.quote,
  });

  final String requestId;
  final String requestCode;
  final String title;
  final String requestStatus;
  final String stage;
  final Map<String, dynamic>? quote;
}

class _QuoteDraftInput {
  const _QuoteDraftInput({
    required this.subtotal,
    required this.discount,
    required this.tax,
  });

  final String subtotal;
  final String discount;
  final String tax;
}
