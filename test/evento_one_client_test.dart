import 'dart:convert';
import 'dart:io';

import 'package:evento_mobile/data/one/evento_one_client.dart';
import 'package:evento_mobile/domain/one/read_models.dart';
import 'package:flutter_test/flutter_test.dart';

const orgA = '11111111-1111-4111-8111-111111111111';
const orgB = '22222222-2222-4222-8222-222222222222';
const actor = '33333333-3333-4333-8333-333333333333';
const record = '44444444-4444-4444-8444-444444444444';
const customer = '55555555-5555-4555-8555-555555555555';
const service = '66666666-6666-4666-8666-666666666666';
final oneAuth = Uri.parse('https://one.example.invalid');

String token(Uri origin, {String role = 'authenticated'}) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'iss': origin.resolve('auth/v1').toString(), 'role': role}))).replaceAll('=', '')}.signature';
Map<String, dynamic> collection(String resource, Map<String, dynamic> item) => {
  'apiVersion': '1',
  'organizationId': orgA,
  'resource': resource,
  'limit': 50,
  'scope': 'bounded_snapshot',
  'items': [item],
};
Map<String, dynamic> invoice() => {
  'id': record,
  'organizationId': orgA,
  'customerId': customer,
  'invoiceNumber': 'INV-2026-0001',
  'status': 'ISSUED',
  'currency': 'AED',
  'issueDate': '2026-09-28',
  'dueDate': '2026-12-31',
  'totalMinor': 10500,
  'amountPaidMinor': 0,
  'amountDueMinor': 10500,
};

void main() {
  late HttpServer server;
  late EventoOneApiClient client;
  late Map<String, dynamic> body;
  late int responseStatus;
  late List<HttpRequest> requests;
  String? redirect;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    responseStatus = 200;
    requests = [];
    redirect = null;
    body = collection('invoices', invoice());
    server.listen((request) async {
      requests.add(request);
      request.response.statusCode = responseStatus;
      request.response.headers.contentType = ContentType.json;
      if (redirect != null) request.response.headers.set('location', redirect!);
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    client = EventoOneApiClient(
      mode: EventoBackendMode.one,
      apiOrigin: Uri.parse('http://127.0.0.1:${server.port}'),
      authOrigin: oneAuth,
      accessToken: () async => token(oneAuth),
      allowLoopbackDevelopment: true,
    );
  });
  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  test('ONE requires an explicit backend mode and secure origins', () {
    expect(parseEventoBackendMode('legacy'), EventoBackendMode.legacy);
    expect(parseEventoBackendMode('one'), EventoBackendMode.one);
    expect(() => parseEventoBackendMode('automatic'), throwsFormatException);
    expect(
      () => EventoOneApiClient(
        mode: EventoBackendMode.legacy,
        apiOrigin: Uri.parse('https://one.example.invalid'),
        authOrigin: oneAuth,
        accessToken: () async => null,
      ),
      throwsStateError,
    );
    for (final origin in [
      'http://example.invalid',
      'https://user:pass@example.invalid',
      'https://example.invalid/elsewhere',
      'https://example.invalid?token=x',
    ]) {
      expect(
        () => EventoOneApiClient(
          mode: EventoBackendMode.one,
          apiOrigin: Uri.parse(origin),
          authOrigin: oneAuth,
          accessToken: () async => null,
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'context maps actor and memberships through a real loopback HTTP exchange',
    () async {
      body = {
        'apiVersion': '1',
        'actor': {'id': actor},
        'organizations': [
          {
            'id': orgA,
            'displayName': 'Synthetic ONE',
            'slug': 'synthetic-one',
            'role': 'VIEWER',
            'currencyCode': 'AED',
            'locale': 'ar',
            'timezone': 'Asia/Dubai',
          },
        ],
      };
      final context = await client.context();
      expect(context.actorId, actor);
      expect(context.organizations.single.id, orgA);
      expect(context.organizations.single.role, 'VIEWER');
      expect(requests.single.uri.path, '/api/v1/context');
      expect(
        requests.single.headers.value('authorization'),
        'Bearer ${token(oneAuth)}',
      );
    },
  );

  test(
    'typed invoice preserves authoritative integer balances without creating payment state',
    () async {
      final result = await client.invoices(orgA);
      expect(result.single.amountDueMinor, 10500);
      expect(result.single.amountPaidMinor, 0);
      expect(result.single.status, 'ISSUED');
      expect(requests.single.method, 'GET');
      expect(requests.single.uri.path, '/api/v1/organizations/$orgA/invoices');
      expect(requests.single.uri.queryParameters, {'limit': '50'});
      expect(() => result.add(result.single), throwsUnsupportedError);
    },
  );

  test('typed bookings and quotations match v1 summary fields', () async {
    body = collection('bookings', {
      'id': record,
      'organizationId': orgA,
      'customerId': customer,
      'serviceId': service,
      'scheduledStart': '2026-12-01T10:00:00Z',
      'scheduledEnd': '2026-12-01T11:00:00Z',
      'status': 'CONFIRMED',
    });
    expect((await client.bookings(orgA)).single.scheduledStart.isUtc, true);
    body = collection('quotations', {
      'id': record,
      'organizationId': orgA,
      'customerId': customer,
      'quoteNumber': 'Q-2026-0001',
      'status': 'ACCEPTED',
      'currency': 'AED',
      'totalMinor': 10500,
      'validUntil': '2026-12-31',
    });
    expect((await client.quotations(orgA)).single.totalMinor, 10500);
  });

  test(
    'legacy issuer and privileged or absent identity are rejected before network',
    () async {
      for (final value in [
        null,
        token(Uri.parse('https://legacy.example.invalid')),
        token(oneAuth, role: 'service_role'),
        'malformed',
      ]) {
        final rejected = EventoOneApiClient(
          mode: EventoBackendMode.one,
          apiOrigin: Uri.parse('http://127.0.0.1:${server.port}'),
          authOrigin: oneAuth,
          accessToken: () async => value,
          allowLoopbackDevelopment: true,
        );
        try {
          await expectLater(
            rejected.context(),
            throwsA(isA<EventoOneApiException>()),
          );
        } finally {
          rejected.close();
        }
      }
      expect(requests, isEmpty);
    },
  );

  test(
    'cross-tenant, changed API version, wrong resource and unbounded input fail closed',
    () async {
      body['items'] = [
        {...invoice(), 'organizationId': orgB},
      ];
      await expectLater(client.invoices(orgA), throwsFormatException);
      body = collection('invoices', invoice())..['apiVersion'] = '2';
      await expectLater(client.invoices(orgA), throwsFormatException);
      body = collection('payments', invoice());
      await expectLater(client.invoices(orgA), throwsFormatException);
      body = collection('invoices', invoice())..['scope'] = 'full_export';
      await expectLater(client.invoices(orgA), throwsFormatException);
      final before = requests.length;
      await expectLater(
        client.invoices(orgA, limit: 101),
        throwsFormatException,
      );
      await expectLater(client.invoices('not-an-id'), throwsFormatException);
      expect(requests.length, before);
    },
  );

  test(
    'authorization errors are sanitized and redirects never forward the bearer',
    () async {
      for (final status in [401, 403, 503]) {
        responseStatus = status;
        body = {'error': 'untrusted_token_and_sensitive_record'};
        await expectLater(
          client.context(),
          throwsA(
            isA<EventoOneApiException>()
                .having((error) => error.status, 'status', status)
                .having(
                  (error) => error.toString().contains('sensitive_record'),
                  'no body echo',
                  false,
                ),
          ),
        );
      }
      final before = requests.length;
      responseStatus = 302;
      redirect = 'http://127.0.0.1:${server.port}/redirect-target';
      await expectLater(
        client.context(),
        throwsA(isA<EventoOneApiException>()),
      );
      expect(requests.length, before + 1);
    },
  );

  test(
    'malformed amounts, dates, states and booking intervals cannot become valid models',
    () {
      expect(
        () => OneInvoiceSummary.fromJson({...invoice(), 'amountDueMinor': 100}),
        throwsFormatException,
      );
      expect(
        () => OneInvoiceSummary.fromJson({...invoice(), 'totalMinor': 105.0}),
        throwsFormatException,
      );
      expect(
        () =>
            OneInvoiceSummary.fromJson({...invoice(), 'dueDate': '2026-02-30'}),
        throwsFormatException,
      );
      expect(
        () => OneInvoiceSummary.fromJson({...invoice(), 'status': 'PAID'}),
        throwsFormatException,
      );
      expect(
        () => OneBookingSummary.fromJson({
          'id': record,
          'organizationId': orgA,
          'customerId': customer,
          'serviceId': service,
          'scheduledStart': '2026-12-01T11:00:00Z',
          'scheduledEnd': '2026-12-01T10:00:00Z',
          'status': 'PENDING',
        }),
        throwsFormatException,
      );
    },
  );
}
