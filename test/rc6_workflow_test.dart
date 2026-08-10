import 'package:flutter_test/flutter_test.dart';
import 'package:evento_mobile/domain/project_workflow.dart';

void main() {
  test('workflow record localizes scope stages', () {
    final ProjectWorkflowRecord flow = ProjectWorkflowRecord.fromJson(<String, dynamic>{
      'request_id': 'request-1',
      'current_stage': 'scope_review',
      'progress_percent': 20,
      'estimated_price_aed': null,
      'scope_approved_at': null,
      'updated_at': DateTime.utc(2026, 8, 10).toIso8601String(),
    });

    expect(flow.progressPercent, 20);
    expect(flow.localizedStage(true), 'مراجعة النطاق');
    expect(flow.localizedStage(false), 'Scope review');
  });

  test('workflow supports future delivery stages', () {
    final ProjectWorkflowRecord flow = ProjectWorkflowRecord.fromJson(<String, dynamic>{
      'request_id': 'request-2',
      'current_stage': 'ready_to_deliver',
      'progress_percent': 100,
      'estimated_price_aed': 12900,
      'scope_approved_at': DateTime.utc(2026, 8, 10).toIso8601String(),
      'updated_at': DateTime.utc(2026, 8, 10).toIso8601String(),
    });

    expect(flow.localizedStage(true), 'جاهز للتسليم');
    expect(flow.localizedStage(false), 'Ready to deliver');
    expect(flow.estimatedPriceAed, 12900);
  });
}
