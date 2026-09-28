import 'dart:convert';
import 'dart:io';

import '../../domain/one/read_models.dart';

/// This opt-in transport is not wired into the current legacy UI or OTP session.
enum EventoBackendMode { legacy, one }

EventoBackendMode parseEventoBackendMode(String value) => switch (value) {
  'legacy' => EventoBackendMode.legacy,
  'one' => EventoBackendMode.one,
  _ => throw const FormatException('Unsupported EVENTO backend mode'),
};

class EventoOneApiException implements Exception {
  const EventoOneApiException(this.status, this.code);
  final int status;
  final String code;
  @override
  String toString() => 'EVENTO ONE API $status: $code';
}

class EventoOneApiClient {
  EventoOneApiClient({
    required EventoBackendMode mode,
    required Uri apiOrigin,
    required Uri authOrigin,
    required Future<String?> Function() accessToken,
    bool allowLoopbackDevelopment = false,
  }) : _apiOrigin = _origin(apiOrigin, allowLoopbackDevelopment),
       _authOrigin = _origin(authOrigin, allowLoopbackDevelopment),
       _accessToken = accessToken {
    if (mode != EventoBackendMode.one) {
      throw StateError('EVENTO ONE requires explicit one backend mode');
    }
    _http.connectionTimeout = const Duration(seconds: 15);
  }

  final Uri _apiOrigin;
  final Uri _authOrigin;
  final Future<String?> Function() _accessToken;
  final HttpClient _http = HttpClient();
  static const _timeout = Duration(seconds: 15);
  static const _maximumResponseBytes = 256 * 1024;

  static Uri _origin(Uri uri, bool local) {
    final isLoopback = ['127.0.0.1', '::1'].contains(uri.host);
    if ((uri.scheme != 'https' &&
            !(local && uri.scheme == 'http' && isLoopback && uri.hasPort)) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException(
        'A secure explicit EVENTO ONE origin is required',
      );
    }
    return uri.replace(path: '/');
  }

  /// Issuer comparison only prevents accidental legacy-token routing. It is not
  /// signature verification or authorization: the ONE server verifies the JWT.
  String _tokenForOne(String? token) {
    if (token == null ||
        token.length > 8192 ||
        !RegExp(r'^[A-Za-z0-9._~-]+$').hasMatch(token)) {
      throw const EventoOneApiException(401, 'authentication_required');
    }
    try {
      final pieces = token.split('.');
      if (pieces.length != 3) throw const FormatException();
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(pieces[1]))),
      );
      if (claims is! Map<String, dynamic> ||
          claims['iss'] != _authOrigin.resolve('auth/v1').toString() ||
          claims['role'] != 'authenticated') {
        throw const FormatException();
      }
    } catch (_) {
      throw const EventoOneApiException(401, 'one_identity_required');
    }
    return token;
  }

  Future<Map<String, dynamic>> _get(String path, {int? limit}) async {
    final token = _tokenForOne(await _accessToken());
    final target = _apiOrigin
        .resolve(path)
        .replace(queryParameters: limit == null ? null : {'limit': '$limit'});
    final request = await _http.getUrl(target).timeout(_timeout);
    // Never carry an Authorization header to a redirected origin.
    request.followRedirects = false;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != 200) {
      // Do not echo arbitrary server bodies, identities or credential material.
      await response.drain<void>().timeout(_timeout);
      final code = switch (response.statusCode) {
        401 => 'authentication_required',
        403 => 'organization_access_denied',
        429 || 503 => 'api_unavailable',
        _ => 'request_failed',
      };
      throw EventoOneApiException(response.statusCode, code);
    }
    if (response.headers.contentType?.mimeType != 'application/json') {
      throw const FormatException('Unexpected EVENTO ONE response type');
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(_timeout)) {
      if (bytes.length + chunk.length > _maximumResponseBytes) {
        throw const FormatException('EVENTO ONE response is too large');
      }
      bytes.addAll(chunk);
    }
    final body = readObject(jsonDecode(utf8.decode(bytes)));
    if (body['apiVersion'] != '1')
      throw const FormatException('Unsupported EVENTO ONE API version');
    return body;
  }

  Future<OneContext> context() async =>
      OneContext.fromJson(await _get('/api/v1/context'));

  Future<List<T>> _list<T>(
    String organizationId,
    String resource,
    T Function(Map<String, dynamic>) parse, {
    int limit = 50,
  }) async {
    final id = readUuid(organizationId);
    if (limit < 1 || limit > 100)
      throw const FormatException('Read limit must be 1 through 100');
    final body = await _get(
      '/api/v1/organizations/$id/$resource',
      limit: limit,
    );
    if (body['organizationId'] != id ||
        body['resource'] != resource ||
        body['limit'] != limit ||
        body['scope'] != 'bounded_snapshot' ||
        body['items'] is! List ||
        (body['items'] as List).length > limit) {
      throw const FormatException('Invalid EVENTO ONE collection envelope');
    }
    return List<T>.unmodifiable(
      (body['items'] as List).map((row) {
        final item = readObject(row);
        if (item['organizationId'] != id)
          throw const FormatException('Cross-organization response rejected');
        return parse(item);
      }),
    );
  }

  Future<List<OneBookingSummary>> bookings(
    String organizationId, {
    int limit = 50,
  }) => _list(
    organizationId,
    'bookings',
    OneBookingSummary.fromJson,
    limit: limit,
  );
  Future<List<OneQuotationSummary>> quotations(
    String organizationId, {
    int limit = 50,
  }) => _list(
    organizationId,
    'quotations',
    OneQuotationSummary.fromJson,
    limit: limit,
  );
  Future<List<OneInvoiceSummary>> invoices(
    String organizationId, {
    int limit = 50,
  }) => _list(
    organizationId,
    'invoices',
    OneInvoiceSummary.fromJson,
    limit: limit,
  );

  void close() => _http.close(force: true);
}
