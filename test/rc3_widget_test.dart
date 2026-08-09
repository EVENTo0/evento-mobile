import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:evento_mobile/rc3_app.dart';

void main() {
  testWidgets('RC3 opens the 50-project customer catalog', (WidgetTester tester) async {
    await tester.pumpWidget(const EventoRc3App());

    expect(find.text('EVENTO'), findsOneWidget);
    await tester.tap(find.text('المشاريع'));
    await tester.pumpAndSettle();

    expect(find.text('50/50'), findsOneWidget);
    expect(find.text('Startup Generator'), findsOneWidget);
  });

  testWidgets('RC3 analyzes a project request locally', (WidgetTester tester) async {
    await tester.pumpWidget(const EventoRc3App());

    await tester.tap(find.text('اطلب'));
    await tester.pumpAndSettle();

    final Finder fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'تطبيق EVENTO تجريبي');
    await tester.enterText(
      fields.at(1),
      'أريد تطبيق هاتف فيه تسجيل دخول ودفع وإشعارات ولوحة إدارة وتحليل AI ومتابعة حالة الطلب.',
    );
    await tester.tap(find.text('حلّل وأنشئ الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('نطاق MVP المقترح'), findsOneWidget);
    expect(find.text('مخاطر يجب ضبطها'), findsOneWidget);
  });

  testWidgets('RC3 switches from Arabic to English', (WidgetTester tester) async {
    await tester.pumpWidget(const EventoRc3App());

    await tester.tap(find.byTooltip('English'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Request'), findsOneWidget);
  });
}
