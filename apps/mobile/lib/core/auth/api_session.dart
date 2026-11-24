import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Runtime-only view of the existing SDK session; never serialized or logged.
class ApiSession {
  const ApiSession(
    this.userId,
    this.accessToken,
    this.expired,
    this.generation,
  );
  final String userId;
  final String accessToken;
  final bool expired;
  final int generation;
}

abstract interface class ApiSessionSource {
  ApiSession? get current;
  Future<void> refresh();
}

class SupabaseApiSession implements ApiSessionSource {
  SupabaseApiSession(this.auth) {
    _subscription = auth.onAuthStateChange.listen(
      (event) {
        if (event.event == AuthChangeEvent.signedOut ||
            event.event == AuthChangeEvent.signedIn) {
          _generation++;
        }
      },
      onError: (Object _) {
        _generation++;
      },
    );
  }
  final GoTrueClient auth;
  late final StreamSubscription<AuthState> _subscription;
  int _generation = 0;
  @override
  ApiSession? get current {
    final session = auth.currentSession;
    return session == null
        ? null
        : ApiSession(
            session.user.id,
            session.accessToken,
            session.isExpired,
            _generation,
          );
  }

  @override
  Future<void> refresh() async {
    await auth.refreshSession();
  }

  void dispose() {
    _subscription.cancel();
  }
}
