import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/auth/api_session.dart';
import '../../core/network/laravel_api.dart';
import '../academic_profile/data/academic_profile_repository.dart';
import '../academic_profile/presentation/profile_controller.dart';
import '../academic_profile/presentation/profile_validation_panel.dart';
import 'development_api.dart';

class AuthValidationPage extends StatefulWidget {
  const AuthValidationPage({super.key});

  @override
  State<AuthValidationPage> createState() => _AuthValidationPageState();
}

class _AuthValidationPageState extends State<AuthValidationPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<AuthState>? _events;
  bool _busy = false;
  String _result =
      'Run connectivity checks, then use a development test account.';
  final _auth = Supabase.instance.client.auth;
  late final SupabaseApiSession _sessions;
  late final LaravelApi _api;
  late final ProfileController _profile;

  @override
  void initState() {
    super.initState();
    _sessions = SupabaseApiSession(_auth);
    _api = LaravelApi(baseUrl: AppConfig.apiBaseUrl, sessions: _sessions);
    _profile = ProfileController(AcademicProfileRepository(_api));
    _events = _auth.onAuthStateChange.listen(
      (event) {
        if (event.event == AuthChangeEvent.signedOut ||
            event.event == AuthChangeEvent.signedIn) {
          _profile.clear();
        }
        if (mounted) setState(() {});
      },
      onError: (Object _) {
        _profile.clear();
        if (mounted) {
          setState(() => _result = 'Session recovery failed. Retry login.');
        }
      },
    );
  }

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) {
        setState(
          () => _result =
              'Check failed. Verify network and test-account credentials.',
        );
      }
    } finally {
      _password.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _checkIdentity() async {
    if (_sessions.current == null) return 'No session. Log in first.';
    final first = await _api.getIdentity();
    final second = await _api.getIdentity();
    if (first != second) return 'Session changed. Verify again.';
    return 'PASS: two /me requests match Supabase UUID $first. Verify database count separately.';
  }

  @override
  Widget build(BuildContext context) {
    final session = _auth.currentSession;
    return Scaffold(
      appBar: AppBar(title: const Text('Re development auth validation')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Development test accounts only. Never paste credentials into chat or logs.',
          ),
          Text('API: ${AppConfig.apiBaseUrl}'),
          Text('Auth project: ${Uri.parse(AppConfig.supabaseUrl).host}'),
          Text(
            session == null
                ? 'Session: signed out'
                : 'Cached session UUID: ${session.user.id}. Verify with /me.',
          ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Test email'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Test password'),
          ),
          ElevatedButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final ok = await DevelopmentApi(AppConfig.apiBaseUrl)
                        .checkGuestBoundary();
                    return ok
                        ? 'PASS: emulator API health, missing-token 401 and invalid-token 401.'
                        : 'Connectivity or rejection check failed.';
                  }),
            child: const Text('Check connection and token rejection'),
          ),
          ElevatedButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    await _auth.signInWithPassword(
                      email: _email.text.trim(),
                      password: _password.text,
                    );
                    _password.clear();
                    return _checkIdentity();
                  }),
            child: const Text('Log in and verify /me'),
          ),
          ElevatedButton(
            onPressed: _busy ? null : () => _run(_checkIdentity),
            child: const Text('Verify restored session with /me'),
          ),
          ElevatedButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    await _auth.signOut(scope: SignOutScope.local);
                    _email.clear();
                    return 'Signed out. Restart the app and confirm Session: signed out.';
                  }),
            child: const Text('Log out'),
          ),
          if (_busy) const LinearProgressIndicator(),
          SelectableText(_result),
          ProfileValidationPanel(controller: _profile),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _events?.cancel();
    _profile.dispose();
    _sessions.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
