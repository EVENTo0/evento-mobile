// Real pinned Supabase SDK + typed client over loopback HTTP fixtures.
// These synthetic Auth responses prove wiring, not server authentication/RLS.
import 'dart:convert';
import 'dart:io';

import 'package:evento_mobile/data/one/evento_one_client.dart';
import 'package:evento_mobile/data/one/one_build_config.dart';
import 'package:evento_mobile/data/one/one_member_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/one_fixtures.dart';

class _WireClient implements HttpClient {
  _WireClient(this.inner, this.port, this.destinations);
  final HttpClient inner;
  final int port;
  final List<Uri> destinations;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    if (url.scheme != 'https' ||
        !{
          'one-auth.example.invalid',
          'one-api.example.invalid',
        }.contains(url.host)) {
      throw StateError(
        'Only fixed synthetic origins may enter this test fixture',
      );
    }
    destinations.add(url);
    return inner.openUrl(
      method,
      url.replace(scheme: 'http', host: '127.0.0.1', port: port),
    );
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  set connectionTimeout(Duration? value) {
    inner.connectionTimeout = value;
  }

  @override
  void close({bool force = false}) => inner.close(force: force);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'pinned Supabase SDK authenticates on the exact ONE origin/path then typed API reads; logout blocks reuse',
    () async {
      await _wireTest();
    },
  );
  test('verified Auth actor mismatch cannot open the ONE context', () async {
    await _wireTest(mismatch: true);
  });
}

Future<void> _wireTest({bool mismatch = false}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  // Create native clients outside the override to avoid recursion or external network.
  final clients = List.generate(8, (_) => HttpClient());
  final available = List<HttpClient>.from(clients);
  final destinations = <Uri>[];
  final paths = <String>[];
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final jwt =
      'header.${base64Url.encode(utf8.encode(jsonEncode({'iss': 'https://one-auth.example.invalid/auth/v1', 'sub': actor, 'role': 'authenticated', 'exp': now + 3600, 'iat': now}))).replaceAll('=', '')}.signature';
  final user = {
    'id': actor,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'fixture@example.invalid',
    'app_metadata': <String, Object>{},
    'user_metadata': <String, Object>{},
    'created_at': '2026-09-28T00:00:00Z',
    'is_anonymous': false,
  };
  server.listen((request) async {
    paths.add('${request.method} ${request.uri.path}');
    request.response.headers.contentType = ContentType.json;
    Object body = <String, Object>{};
    if (request.uri.path == '/auth/v1/token' && request.method == 'POST') {
      expect(request.uri.queryParameters['grant_type'], 'password');
      final posted = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      expect(posted['email'], 'fixture@example.invalid');
      expect(posted['password'], 'synthetic fixture password');
      body = {
        'access_token': jwt,
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': now + 3600,
        'refresh_token': 'synthetic_refresh_fixture',
        'user': user,
      };
    } else if (request.uri.path == '/auth/v1/user') {
      expect(request.headers.value('authorization'), 'Bearer $jwt');
      body = {...user, if (mismatch) 'id': customer};
    } else if (request.uri.path == '/auth/v1/logout') {
      expect(request.uri.queryParameters['scope'], 'local');
      request.response.statusCode = 204;
      await request.response.close();
      return;
    } else if (request.uri.path.startsWith('/api/v1/')) {
      expect(request.headers.value('authorization'), 'Bearer $jwt');
      expect(request.method, 'GET');
      body = request.uri.path == '/api/v1/context'
          ? contextBody()
          : collection(request.uri.pathSegments.last, orgA);
    } else {
      request.response.statusCode = 404;
    }
    request.response.write(jsonEncode(body));
    await request.response.close();
  });
  try {
    await HttpOverrides.runZoned(
      () async {
        final gateway = SupabaseOneMemberGateway(
          OneBuildConfig.parse({
            'EVENTO_BACKEND_MODE': 'one',
            'EVENTO_ONE_API_ORIGIN': 'https://one-api.example.invalid/',
            'EVENTO_ONE_SUPABASE_URL': 'https://one-auth.example.invalid/',
            'EVENTO_ONE_PUBLISHABLE_KEY': 'sb_publishable_synthetic',
          })!,
        );
        try {
          if (mismatch) {
            await expectLater(
              gateway.signIn(
                'fixture@example.invalid',
                'synthetic fixture password',
              ),
              throwsA(isA<EventoOneApiException>()),
            );
            expect(paths.where((path) => path.contains('/api/')), isEmpty);
          } else {
            await gateway.signIn(
              'fixture@example.invalid',
              'synthetic fixture password',
            );
            final context = await gateway.context();
            expect(context.actorId, actor);
            final records = await gateway.read(orgA);
            expect(records.bookings.single.organizationId, orgA);
            expect(records.quotations.single.quoteNumber, 'SYNTHETIC-Q-A');
            expect(records.invoices.single.amountDueMinor, 5500);
            await gateway.signOut();
            final count = paths.length;
            await expectLater(
              gateway.context(),
              throwsA(isA<EventoOneApiException>()),
            );
            expect(paths.length, count);
            expect(paths, contains('POST /auth/v1/logout'));
          }
          expect(paths.take(2), ['POST /auth/v1/token', 'GET /auth/v1/user']);
          expect(destinations.every((uri) => !uri.path.startsWith('//')), true);
          expect(
            destinations
                .where((uri) => uri.path.startsWith('/api/'))
                .every((uri) => uri.host == 'one-api.example.invalid'),
            true,
          );
          expect(
            destinations
                .where((uri) => uri.path.startsWith('/auth/'))
                .every((uri) => uri.host == 'one-auth.example.invalid'),
            true,
          );
        } finally {
          await gateway.close();
        }
      },
      createHttpClient: (_) =>
          _WireClient(available.removeLast(), server.port, destinations),
    );
  } finally {
    for (final client in clients) {
      client.close(force: true);
    }
    await server.close(force: true);
  }
}
