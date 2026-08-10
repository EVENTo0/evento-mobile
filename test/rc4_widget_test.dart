import 'package:flutter_test/flutter_test.dart';

import 'package:evento_mobile/domain/request_live_detail.dart';
import 'package:evento_mobile/rc4_app.dart';

void main() {
  testWidgets('RC4 exposes the 50-project catalog', (WidgetTester tester) async {
    await tester.pumpWidget(const EventoRc4App());

    expect(find.text('EVENTO'), findsOneWidget);
    await tester.tap(find.text('المشاريع'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/50'), findsOneWidget);
    expect(find.text('Startup Generator'), findsOneWidget);
  });

  testWidgets('RC4 routes unsigned live request to account', (WidgetTester tester) async {
    await tester.pumpWidget(const EventoRc4App());

    await tester.tap(find.text('اطلب'));
    await tester.pumpAndSettle();

    final Finder fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'EVENTO RC4 test');
    await tester.enterText(fields.at(1), 'A sufficiently detailed mobile application request for EVENTO live testing.');
    await tester.tap(find.text('اذهب إلى تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('حساب EVENTO'), findsOneWidget);
  });

  testWidgets('RC4 switches to English', (WidgetTester tester) async {
    await tester.pumpWidget(const EventoRc4App());
    await tester.tap(find.byTooltip('English'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My live requests'), findsOneWidget);
  });

  test('live analysis and timeline models parse Supabase rows', () {
    final RequestAnalysisRecord analysis = RequestAnalysisRecord.fromJson(<String, dynamic>{
      'complexity': 'high',
      'summary': 'Server result',
      'proposed_scope': <String>['auth', 'ai'],
      'risks': <String>['RLS'],
      'engine_version': 'evento-test',
      'updated_at': '2026-08-09T23:56:08.490834Z',
    });
    final RequestEventRecord event = RequestEventRecord.fromJson(<String, dynamic>{
      'status': 'analyzed',
      'note': 'Initial server analysis completed.',
      'created_at': '2026-08-09T23:56:08.490834Z',
    });

    expect(analysis.complexity, 'high');
    expect(analysis.proposedScope, contains('ai'));
    expect(event.status, 'analyzed');
  });
}
