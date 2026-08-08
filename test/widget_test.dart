import 'package:flutter_test/flutter_test.dart';

import 'package:evento_mobile/main.dart';

void main() {
  testWidgets('EVENTO shell loads and navigates to request', (tester) async {
    await tester.pumpWidget(const EventoApp(liveConfigured: false));

    expect(find.text('EVENTO'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);

    await tester.tap(find.text('طلب'));
    await tester.pumpAndSettle();

    expect(find.text('حلّل فكرة مشروعك'), findsOneWidget);
  });

  testWidgets('language toggle switches navigation labels', (tester) async {
    await tester.pumpWidget(const EventoApp(liveConfigured: false));

    await tester.tap(find.byTooltip('English'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
  });
}
