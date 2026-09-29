import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/one/evento_one_client.dart';
import '../../data/one/one_member_gateway.dart';
import '../../domain/one/read_models.dart';

enum OneMemberState {
  disabled,
  signedOut,
  signingIn,
  loading,
  ready,
  denied,
  unavailable,
}

class OneMemberController extends ChangeNotifier {
  OneMemberController(this.gateway)
    : state = gateway == null
          ? OneMemberState.disabled
          : OneMemberState.signedOut {
    _subscription = gateway?.invalidations.listen(
      (_) => _reset('session_expired'),
    );
  }
  final OneMemberGateway? gateway;
  StreamSubscription<void>? _subscription;
  OneMemberState state;
  OneContext? context;
  OneOrganization? organization;
  OneMemberSnapshot? data;
  String? message;
  int _generation = 0;
  bool _disposed = false;
  bool get busy =>
      state == OneMemberState.signingIn || state == OneMemberState.loading;
  bool _current(int value) => !_disposed && value == _generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _clear() {
    context = null;
    organization = null;
    data = null;
  }

  void _reset(String? reason) {
    ++_generation;
    _clear();
    message = reason;
    state = gateway == null
        ? OneMemberState.disabled
        : OneMemberState.signedOut;
    _notify();
  }

  Future<void> signIn(String email, String password) async {
    if (gateway == null || busy || context != null) return;
    final generation = ++_generation;
    _clear();
    message = null;
    state = OneMemberState.signingIn;
    _notify();
    try {
      await gateway!.signIn(email, password);
      if (!_current(generation)) return;
      await _loadContext(generation);
    } catch (_) {
      if (!_current(generation)) return;
      _reset('login_failed');
      await gateway!.signOut();
    }
  }

  Future<void> _loadContext(int generation) async {
    final loaded = await gateway!.context();
    if (!_current(generation)) return;
    final previousId = organization?.id;
    context = loaded;
    organization =
        loaded.organizations.where((org) => org.id == previousId).firstOrNull ??
        loaded.organizations.firstOrNull;
    if (organization == null) {
      state = OneMemberState.ready;
      data = null;
      _notify();
      return;
    }
    await _read(generation);
  }

  Future<void> refresh({bool invalidatePending = false}) async {
    if (gateway == null || context == null || (busy && !invalidatePending))
      return;
    final generation = ++_generation;
    data = null;
    message = null;
    state = OneMemberState.loading;
    _notify();
    try {
      await _loadContext(generation);
    } catch (error) {
      _fail(error, generation);
    }
  }

  Future<void> selectOrganization(String id) async {
    if (gateway == null || context == null) return;
    final generation = ++_generation;
    data = null;
    message = null;
    organization = context!.organizations
        .where((org) => org.id == id)
        .firstOrNull;
    if (organization == null) {
      state = OneMemberState.denied;
      message = 'access_denied';
      _notify();
      return;
    }
    state = OneMemberState.loading;
    _notify();
    await _read(generation);
  }

  Future<void> _read(int generation) async {
    try {
      final id = organization!.id;
      final loaded = await gateway!.read(id);
      if (!_current(generation) || organization?.id != id) return;
      data = loaded;
      state = OneMemberState.ready;
      _notify();
    } catch (error) {
      _fail(error, generation);
    }
  }

  void _fail(Object error, int generation) {
    if (!_current(generation)) return;
    data = null;
    if (error is EventoOneApiException && error.status == 401) {
      _reset('session_expired');
      unawaited(gateway!.signOut());
      return;
    }
    state = error is EventoOneApiException && error.status == 403
        ? OneMemberState.denied
        : OneMemberState.unavailable;
    message = state == OneMemberState.denied ? 'access_denied' : 'unavailable';
    _notify();
  }

  Future<void> signOut() async {
    _reset(null);
    await gateway?.signOut();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    unawaited(_subscription?.cancel());
    unawaited(gateway?.close());
    _clear();
    super.dispose();
  }
}
