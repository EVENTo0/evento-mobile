import 'package:evento_mobile/domain/project_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a reviewed EVENTO contract version', () {
    final contract = ProjectContractVersionRecord.fromJson(<String, dynamic>{
      'id': 'contract-1',
      'contract_code': 'EVC-260812-ABC123',
      'request_id': 'request-1',
      'quote_id': 'quote-1',
      'version_number': 2,
      'status': 'sent',
      'terms_version': 'terms-2026.08',
      'statement_of_work': <String>['Build portal'],
      'deliverables': <String>['Source', 'Preview'],
      'acceptance_criteria': <String>['CI green'],
      'rendered_terms_ar': 'هذه شروط تجريبية طويلة بما يكفي لاختبار قراءة النسخة المراجعة داخل التطبيق.',
      'rendered_terms_en': 'Reviewed test contract terms for the EVENTO mobile reconciliation flow.',
      'legal_review_status': 'approved_for_use',
      'valid_until': '2099-08-19T12:00:00Z',
      'accepted_at': null,
    });

    expect(contract.contractCode, 'EVC-260812-ABC123');
    expect(contract.versionNumber, 2);
    expect(contract.deliverables, contains('Preview'));
    expect(contract.isAcceptable, isTrue);
  });

  test('does not allow an unreviewed contract to be accepted', () {
    final contract = ProjectContractVersionRecord.fromJson(<String, dynamic>{
      'id': 'contract-2',
      'contract_code': 'EVC-260812-DEF456',
      'request_id': 'request-2',
      'quote_id': 'quote-2',
      'version_number': 1,
      'status': 'sent',
      'terms_version': 'terms-2026.08',
      'statement_of_work': const <String>[],
      'deliverables': const <String>[],
      'acceptance_criteria': const <String>[],
      'rendered_terms_ar': 'هذه نسخة غير معتمدة للاستخدام ويجب ألا يسمح التطبيق بقبولها من العميل.',
      'rendered_terms_en': null,
      'legal_review_status': 'reviewed',
      'valid_until': '2099-08-19T12:00:00Z',
      'accepted_at': null,
    });

    expect(contract.isAcceptable, isFalse);
  });
}
