import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:evento_mobile/domain/request_live_detail.dart';
import 'package:evento_mobile/rc5_app.dart';

void main() {
  testWidgets('RC5 exposes bilingual live shell and 50-project catalog', (WidgetTester tester) async {
    await tester.pumpWidget(const EventoRc5App());

    expect(find.text('EVENTO'), findsOneWidget);
    expect(find.text('RC5 • BILINGUAL LIVE'), findsOneWidget);

    await tester.tap(find.text('المشاريع'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/50'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('RC5 switches navigation to English', (WidgetTester tester) async {
    await tester.pumpWidget(const EventoRc5App());

    await tester.tap(find.byTooltip('English'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Request'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });

  test('analysis model prefers Arabic fields when present', () {
    final RequestAnalysisRecord record = RequestAnalysisRecord.fromJson(<String, dynamic>{
      'complexity': 'high',
      'summary': 'English summary',
      'summary_ar': 'ملخص عربي',
      'proposed_scope': <String>['Capability: auth'],
      'proposed_scope_ar': <String>['قدرة مطلوبة: تسجيل الدخول'],
      'risks': <String>['English risk'],
      'risks_ar': <String>['مخاطرة عربية'],
      'engine_version': 'evento-heuristic-v1.0-rc5',
      'updated_at': '2026-08-10T10:00:00Z',
    });

    expect(record.localizedSummary(true), 'ملخص عربي');
    expect(record.localizedSummary(false), 'English summary');
    expect(record.localizedScope(true), contains('قدرة مطلوبة: تسجيل الدخول'));
    expect(record.localizedRisks(true), contains('مخاطرة عربية'));
    expect(record.isRc5OrNewer, isTrue);
  });

  test('timeline model localizes status and note', () {
    final RequestEventRecord event = RequestEventRecord.fromJson(<String, dynamic>{
      'status': 'analyzed',
      'note': 'Server analysis completed and synchronized.',
      'note_ar': 'اكتمل التحليل الخادمي وتمت مزامنته.',
      'created_at': '2026-08-10T10:00:00Z',
    });

    expect(event.localizedStatus(true), 'تم التحليل');
    expect(event.localizedStatus(false), 'Analyzed');
    expect(event.localizedNote(true), 'اكتمل التحليل الخادمي وتمت مزامنته.');
  });
}
