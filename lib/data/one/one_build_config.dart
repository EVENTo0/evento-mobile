import 'dart:convert';

class OneBuildConfig {
  OneBuildConfig._(this.apiOrigin, this.authOrigin, this.publishableKey);
  final Uri apiOrigin, authOrigin;
  final String publishableKey;

  static OneBuildConfig? fromEnvironment() => parse({
    'EVENTO_BACKEND_MODE': const String.fromEnvironment('EVENTO_BACKEND_MODE'),
    'EVENTO_ONE_API_ORIGIN': const String.fromEnvironment(
      'EVENTO_ONE_API_ORIGIN',
    ),
    'EVENTO_ONE_SUPABASE_URL': const String.fromEnvironment(
      'EVENTO_ONE_SUPABASE_URL',
    ),
    'EVENTO_ONE_PUBLISHABLE_KEY': const String.fromEnvironment(
      'EVENTO_ONE_PUBLISHABLE_KEY',
    ),
  });

  static OneBuildConfig? parse(Map<String, String> values) {
    if (values['EVENTO_BACKEND_MODE'] != 'one') return null;
    Uri? origin(String? value) {
      final uri = Uri.tryParse(value ?? '');
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          (uri.path.isNotEmpty && uri.path != '/'))
        return null;
      return uri.replace(path: '/');
    }

    final api = origin(values['EVENTO_ONE_API_ORIGIN']);
    final auth = origin(values['EVENTO_ONE_SUPABASE_URL']);
    final key = values['EVENTO_ONE_PUBLISHABLE_KEY'] ?? '';
    var publicKey = RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(key);
    if (!publicKey && key.split('.').length == 3) {
      try {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(key.split('.')[1]))),
        );
        publicKey =
            payload is Map<String, dynamic> && payload['role'] == 'anon';
      } catch (_) {
        /* fail closed */
      }
    }
    if (api == null || auth == null || !publicKey) return null;
    return OneBuildConfig._(api, auth, key);
  }
}
