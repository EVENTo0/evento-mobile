import 'dart:async';
import 'dart:convert';

import 'package:evento_mobile/data/one/evento_one_client.dart';
import 'package:evento_mobile/data/one/one_build_config.dart';
import 'package:evento_mobile/data/one/one_member_gateway.dart';
import 'package:evento_mobile/domain/one/read_models.dart';
import 'package:evento_mobile/features/one/one_member_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/one_fixtures.dart';

void main() {
  late FakeOneGateway gateway;
  late OneMemberController controller;
  setUp(() {
    gateway = FakeOneGateway();
    controller = OneMemberController(gateway);
  });
  tearDown(() => controller.dispose());

  test(
    'build config requires explicit ONE mode, HTTPS origins and a public key',
    () {
      final values = <String, String>{
        'EVENTO_BACKEND_MODE': 'one',
        'EVENTO_ONE_API_ORIGIN': 'https://one-api.example.invalid',
        'EVENTO_ONE_SUPABASE_URL': 'https://one-auth.example.invalid/',
        'EVENTO_ONE_PUBLISHABLE_KEY': 'sb_publishable_synthetic',
      };
      final config = OneBuildConfig.parse(values)!;
      expect(config.authOrigin.origin, 'https://one-auth.example.invalid');
      expect(OneBuildConfig.parse({}), isNull);
      for (final entry in {
        'EVENTO_BACKEND_MODE': 'legacy',
        'EVENTO_ONE_API_ORIGIN': 'http://one-api.example.invalid',
        'EVENTO_ONE_SUPABASE_URL':
            'https://name:secret@one-auth.example.invalid',
        'EVENTO_ONE_PUBLISHABLE_KEY': 'sb_secret_synthetic',
      }.entries) {
        expect(
          OneBuildConfig.parse({...values, entry.key: entry.value}),
          isNull,
        );
      }
      for (final value in [
        'https://auth.example.invalid/subpath',
        'https://auth.example.invalid?key=x',
        'https://auth.example.invalid#x',
      ]) {
        expect(
          OneBuildConfig.parse({...values, 'EVENTO_ONE_SUPABASE_URL': value}),
          isNull,
        );
      }
      for (final role in ['service_role', 'authenticated']) {
        final key =
            'header.${base64Url.encode(utf8.encode(jsonEncode({'role': role})))}.signature';
        expect(
          OneBuildConfig.parse({...values, 'EVENTO_ONE_PUBLISHABLE_KEY': key}),
          isNull,
        );
      }
      expect(
        OneBuildConfig.parse({
          'SUPABASE_URL': values['EVENTO_ONE_SUPABASE_URL']!,
          'SUPABASE_ANON_KEY': values['EVENTO_ONE_PUBLISHABLE_KEY']!,
        }),
        isNull,
      );
    },
  );

  test(
    'sign in loads the member context and first permitted organization only',
    () async {
      await controller.signIn('member@example.invalid', 'synthetic');
      expect(controller.state, OneMemberState.ready);
      expect(controller.context!.actorId, actor);
      expect(controller.organization!.id, orgA);
      expect(controller.data!.invoices.single.organizationId, orgA);
      expect(gateway.reads, [orgA]);
    },
  );

  test(
    'empty membership context does not invent an organization or read records',
    () async {
      gateway.resultContext = OneContext.fromJson(
        contextBody(organizations: []),
      );
      await controller.signIn('member@example.invalid', 'synthetic');
      expect(controller.state, OneMemberState.ready);
      expect(controller.organization, isNull);
      expect(controller.data, isNull);
      expect(gateway.reads, isEmpty);
    },
  );

  test(
    'organization switch clears data and ignores a late response from another tenant',
    () async {
      await controller.signIn('member@example.invalid', 'synthetic');
      final pending = Completer<OneMemberSnapshot>();
      gateway.onRead = (id) =>
          id == orgA ? pending.future : Future.value(snapshot(orgB));
      final stale = controller.selectOrganization(orgA);
      expect(controller.data, isNull);
      await controller.selectOrganization(orgB);
      pending.complete(snapshot(orgA));
      await stale;
      expect(controller.organization!.id, orgB);
      expect(controller.data!.invoices.single.organizationId, orgB);
    },
  );

  test(
    'ungranted organization selection clears records without an API request',
    () async {
      await controller.signIn('member@example.invalid', 'synthetic');
      await controller.selectOrganization(customer);
      expect(controller.state, OneMemberState.denied);
      expect(controller.data, isNull);
      expect(gateway.reads, [orgA]);
    },
  );

  test(
    '403 denial and provider outage hide old data and never use legacy fallback',
    () async {
      await controller.signIn('member@example.invalid', 'synthetic');
      gateway.onRead = (_) =>
          Future.error(const EventoOneApiException(403, 'opaque'));
      await controller.refresh();
      expect(controller.state, OneMemberState.denied);
      expect(controller.data, isNull);
      gateway.onRead = (_) =>
          Future.error(const EventoOneApiException(503, 'opaque'));
      await controller.refresh();
      expect(controller.state, OneMemberState.unavailable);
      expect(controller.message, 'unavailable');
      expect(controller.data, isNull);
    },
  );

  test(
    '401 clears identity, organization and records before returning to login',
    () async {
      await controller.signIn('member@example.invalid', 'synthetic');
      gateway.onRead = (_) =>
          Future.error(const EventoOneApiException(401, 'opaque'));
      await controller.refresh();
      expect(controller.state, OneMemberState.signedOut);
      expect(controller.context, isNull);
      expect(controller.organization, isNull);
      expect(controller.data, isNull);
      expect(controller.message, 'session_expired');
      expect(gateway.signOuts, 1);
    },
  );

  test('logout and expiry discard any pending read result', () async {
    await controller.signIn('member@example.invalid', 'synthetic');
    final pending = Completer<OneMemberSnapshot>();
    gateway.onRead = (_) => pending.future;
    final stale = controller.selectOrganization(orgB);
    await controller.signOut();
    pending.complete(snapshot(orgB));
    await stale;
    expect(controller.state, OneMemberState.signedOut);
    expect(controller.data, isNull);
    gateway.onRead = null;
    await controller.signIn('member@example.invalid', 'synthetic');
    gateway.events.add(null);
    expect(controller.message, 'session_expired');
    expect(controller.context, isNull);
    expect(controller.data, isNull);
  });

  test(
    'resume revalidates context even during a pending read and rejects its late result',
    () async {
      await controller.signIn('member@example.invalid', 'synthetic');
      final pending = Completer<OneMemberSnapshot>();
      gateway.onRead = (_) => pending.future;
      final stale = controller.selectOrganization(orgA);
      gateway.resultContext = OneContext.fromJson(
        contextBody(organizations: [orgB]),
      );
      gateway.onRead = (_) => Future.value(snapshot(orgB));
      await controller.refresh(invalidatePending: true);
      pending.complete(snapshot(orgA));
      await stale;
      expect(gateway.contexts, 2);
      expect(controller.organization!.id, orgB);
      expect(controller.data!.invoices.single.organizationId, orgB);
    },
  );

  test(
    'failed login is sanitized and retains no organization or records',
    () async {
      gateway.loginError = StateError('sensitive untrusted provider output');
      await controller.signIn('member@example.invalid', 'synthetic');
      expect(controller.state, OneMemberState.signedOut);
      expect(controller.message, 'login_failed');
      expect(controller.context, isNull);
      expect(gateway.signOuts, 1);
    },
  );
}
