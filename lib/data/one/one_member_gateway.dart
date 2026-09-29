import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/one/read_models.dart';
import 'evento_one_client.dart';
import 'one_build_config.dart';

class OneMemberSnapshot {
  const OneMemberSnapshot({
    required this.bookings,
    required this.quotations,
    required this.invoices,
  });
  final List<OneBookingSummary> bookings;
  final List<OneQuotationSummary> quotations;
  final List<OneInvoiceSummary> invoices;
}

abstract interface class OneMemberGateway {
  Stream<void> get invalidations;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<OneContext> context();
  Future<OneMemberSnapshot> read(String organizationId);
  Future<void> close();
}

/// Dedicated in-memory ONE identity. It never initializes or reads Supabase.instance.
/// Login is required after restart/expiry; no token, password or business data is persisted.
class SupabaseOneMemberGateway implements OneMemberGateway {
  SupabaseOneMemberGateway(OneBuildConfig config)
    : _auth = SupabaseClient(
        config.authOrigin.origin,
        config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ) {
    _api = EventoOneApiClient(
      mode: EventoBackendMode.one,
      apiOrigin: config.apiOrigin,
      authOrigin: config.authOrigin,
      accessToken: () async {
        final session = _auth.auth.currentSession;
        if (!_acceptSession || session == null || session.isExpired) {
          _invalidate();
          return null;
        }
        return session.accessToken;
      },
    );
    _subscription = _auth.auth.onAuthStateChange.listen((event) {
      if (_acceptSession && event.event == AuthChangeEvent.signedOut)
        _invalidate();
    }, onError: (_) => _invalidate());
  }
  final SupabaseClient _auth;
  late final EventoOneApiClient _api;
  final _invalidations = StreamController<void>.broadcast(sync: true);
  late final StreamSubscription<AuthState> _subscription;
  Timer? _expiry;
  bool _acceptSession = false;
  bool _closed = false;
  int _loginEpoch = 0;
  @override
  Stream<void> get invalidations => _invalidations.stream;

  void _invalidate() {
    final wasActive = _acceptSession;
    _acceptSession = false;
    _expiry?.cancel();
    if (wasActive && !_closed) _invalidations.add(null);
  }

  @override
  Future<void> signIn(String email, String password) async {
    final epoch = ++_loginEpoch;
    _invalidate();
    final result = await _auth.auth
        .signInWithPassword(email: email.trim(), password: password)
        .timeout(const Duration(seconds: 20));
    final verified = await _auth.auth.getUser().timeout(
      const Duration(seconds: 15),
    );
    if (_closed ||
        epoch != _loginEpoch ||
        result.session == null ||
        verified.user == null ||
        verified.user!.id != result.user?.id ||
        verified.user!.isAnonymous ||
        result.session!.expiresAt == null ||
        result.session!.isExpired) {
      throw const EventoOneApiException(401, 'authentication_required');
    }
    _acceptSession = true;
    _expiry?.cancel();
    _expiry = Timer(
      DateTime.fromMillisecondsSinceEpoch(
        result.session!.expiresAt! * 1000,
      ).difference(DateTime.now()),
      _invalidate,
    );
  }

  @override
  Future<void> signOut() async {
    ++_loginEpoch;
    _acceptSession = false;
    _expiry?.cancel();
    // The pinned SDK removes its in-memory session before its revocation request.
    try {
      await _auth.auth
          .signOut(scope: SignOutScope.local)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      /* Local identity and UI stay cleared even when revocation is unreachable. */
    }
  }

  @override
  Future<OneContext> context() async {
    final result = await _api.context();
    if (!_acceptSession || result.actorId != _auth.auth.currentUser?.id) {
      throw const EventoOneApiException(401, 'authentication_required');
    }
    return result;
  }

  @override
  Future<OneMemberSnapshot> read(String organizationId) async {
    final values = await Future.wait<Object>([
      _api.bookings(organizationId),
      _api.quotations(organizationId),
      _api.invoices(organizationId),
    ]);
    return OneMemberSnapshot(
      bookings: values[0] as List<OneBookingSummary>,
      quotations: values[1] as List<OneQuotationSummary>,
      invoices: values[2] as List<OneInvoiceSummary>,
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    ++_loginEpoch;
    _acceptSession = false;
    _expiry?.cancel();
    await _subscription.cancel();
    _api.close();
    await _auth.dispose();
    await _invalidations.close();
  }
}
