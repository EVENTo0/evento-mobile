import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:evento_mobile/data/one/evento_one_client.dart';
import 'package:evento_mobile/data/one/one_member_gateway.dart';
import 'package:evento_mobile/domain/one/read_models.dart';
import 'package:evento_mobile/features/one/one_member_app.dart';
import 'package:evento_mobile/features/one/one_member_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/one_fixtures.dart';

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['EVENTO_WIDGET_EVIDENCE_DIR'];
  if (directory == null) return;
  final render = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('evidence-boundary')),
  );
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> mount(WidgetTester tester, OneMemberController controller) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final font = Platform.environment['EVENTO_WIDGET_FONT'];
  if (font != null) {
    final loader = FontLoader('Roboto')
      ..addFont(
        Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
      );
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '${File(font).parent.path}/MaterialIcons-Regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
  }
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('evidence-boundary'),
      child: OneMemberApp(controller: controller),
    ),
  );
  await tester.tap(find.byKey(const Key('one-language')));
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('one-email')),
    'member@example.invalid',
  );
  await tester.enterText(
    find.byKey(const Key('one-password')),
    'synthetic fixture only',
  );
  await tester.tap(find.byKey(const Key('one-sign-in')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'credential-free default is disabled TEST with no sign-in form or LIVE claim',
    (tester) async {
      await mount(tester, OneMemberController(null));
      expect(find.byKey(const Key('one-disabled')), findsOneWidget);
      expect(find.byKey(const Key('one-sign-in')), findsNothing);
      expect(find.text('TEST'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
    },
  );

  testWidgets(
    'member login opens all three read views and logout clears the workspace',
    (tester) async {
      final gateway = FakeOneGateway();
      final controller = OneMemberController(gateway);
      await mount(tester, controller);
      await capture(tester, 'one-member-login-rendered-fixture');
      await login(tester);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('2026-12-01 10:00 UTC'), findsOneWidget);
      await tester.tap(find.byKey(const Key('one-quotes-tab')));
      await tester.pumpAndSettle();
      expect(find.text('SYNTHETIC-Q-A'), findsOneWidget);
      expect(find.text('ACCEPTED · AED 105.00'), findsOneWidget);
      await tester.tap(find.byKey(const Key('one-invoices-tab')));
      await tester.pumpAndSettle();
      expect(find.text('SYNTHETIC-INV-A'), findsOneWidget);
      expect(find.textContaining('Due: AED 55.00'), findsOneWidget);
      await capture(tester, 'one-member-invoices-rendered-fixture');
      await tester.tap(find.byKey(const Key('one-logout')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('one-password')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('one-password')))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('SYNTHETIC-INV-A'), findsNothing);
      expect(find.byKey(const Key('one-organizations')), findsNothing);
      expect(gateway.signOuts, 1);
    },
  );

  testWidgets(
    'organization picker uses only context memberships and replaces displayed records',
    (tester) async {
      final controller = OneMemberController(FakeOneGateway());
      await mount(tester, controller);
      await login(tester);
      await tester.tap(find.byKey(const Key('one-organizations')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Synthetic Studio B').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('one-invoices-tab')));
      await tester.pumpAndSettle();
      expect(find.text('SYNTHETIC-INV-B'), findsOneWidget);
      expect(find.text('SYNTHETIC-INV-A'), findsNothing);
      expect(controller.organization!.id, orgB);
    },
  );

  testWidgets(
    'denial hides records, shows retry, and expiry returns to a clear login form',
    (tester) async {
      final gateway = FakeOneGateway();
      final controller = OneMemberController(gateway);
      await mount(tester, controller);
      await login(tester);
      gateway.onRead = (_) =>
          Future.error(const EventoOneApiException(403, 'opaque'));
      await tester.tap(find.byKey(const Key('one-refresh')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('one-error')), findsOneWidget);
      expect(find.byKey(const Key('one-retry')), findsOneWidget);
      expect(find.text('CONFIRMED'), findsNothing);
      gateway.events.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Your session ended. Sign in again.'), findsOneWidget);
      expect(find.byKey(const Key('one-sign-in')), findsOneWidget);
      expect(find.byKey(const Key('one-organizations')), findsNothing);
    },
  );

  testWidgets(
    'empty memberships and empty resource lists have explicit states',
    (tester) async {
      final gateway = FakeOneGateway()
        ..resultContext = OneContext.fromJson(contextBody(organizations: []));
      final controller = OneMemberController(gateway);
      await mount(tester, controller);
      await login(tester);
      expect(find.byKey(const Key('one-no-membership')), findsOneWidget);
      gateway.resultContext = OneContext.fromJson(contextBody());
      gateway.onRead = (_) async =>
          const OneMemberSnapshot(bookings: [], quotations: [], invoices: []);
      await controller.refresh();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('one-empty')), findsOneWidget);
    },
  );

  testWidgets(
    'background hides lists and resume invalidates a pending pre-resume read',
    (tester) async {
      final gateway = FakeOneGateway();
      final controller = OneMemberController(gateway);
      await mount(tester, controller);
      await login(tester);
      final pending = Completer<OneMemberSnapshot>();
      gateway.onRead = (_) => pending.future;
      final stale = controller.selectOrganization(orgA);
      await tester.pump();
      expect(find.byKey(const Key('one-loading')), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      gateway.resultContext = OneContext.fromJson(
        contextBody(organizations: [orgB]),
      );
      gateway.onRead = (_) async => snapshot(orgB);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      pending.complete(snapshot(orgA));
      await stale;
      await tester.pumpAndSettle();
      expect(controller.data!.invoices.single.organizationId, orgB);
      expect(find.text('Synthetic Studio A'), findsNothing);
      expect(gateway.contexts, 2);
    },
  );
}
