import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:re_mobile/core/theme/app_theme.dart';
import 'package:re_mobile/features/auth/auth_gateway.dart';
import 'package:re_mobile/features/auth/auth_controller.dart';
import 'package:re_mobile/features/auth/auth_boundary.dart';

class FakeAuth implements AuthGateway {
  @override
  String? userId;
  final events = StreamController<AuthSignal>.broadcast(sync: true);
  Future<String> Function()? verify;
  Future<void> Function()? action;
  Object? error;
  int logins = 0, registrations = 0, logouts = 0;
  bool autoConfirm = false;
  @override
  Stream<AuthSignal> get changes => events.stream;
  @override
  Future<String> verifySession() async {
    if (verify != null) return verify!();
    if (error != null) throw error!;
    return userId!;
  }

  @override
  Future<void> login(String email, String password) async {
    logins++;
    if (action != null) await action!();
    if (error != null) throw error!;
    userId = 'account-a';
    events.add(AuthSignal.changed);
  }

  @override
  Future<void> register(String email, String password) async {
    registrations++;
    if (error != null) throw error!;
    if (autoConfirm) {
      userId = 'account-a';
      events.add(AuthSignal.changed);
    }
  }

  @override
  Future<void> logout() async {
    logouts++;
    userId = null;
    events.add(AuthSignal.changed);
  }
}

Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  testWidgets(
    'small large-text auth forms scroll and recovery does not send requests',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuth();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onboarding,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: AuthBoundary(gateway: auth),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Sudah punya akun? Masuk'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sudah punya akun? Masuk'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Lupa kata sandi?'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();
      expect(find.text('Pulihkan akses akun'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Tidak ada email pemulihan'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Tidak ada email pemulihan'), findsOneWidget);
      expect(auth.logins + auth.registrations + auth.logouts, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await auth.events.close();
    },
  );
  test('email, login, registration and confirmation validation', () {
    expect(AuthValidation.email('bad'), isNotNull);
    expect(AuthValidation.email(' a@example.test '), isNull);
    expect(AuthValidation.password(''), isNotNull);
    expect(AuthValidation.password('short'), isNull);
    expect(AuthValidation.password('short', registration: true), isNotNull);
    expect(
      AuthValidation.password('long-password', registration: true),
      isNull,
    );
    expect(AuthValidation.confirmation('other', 'password'), isNotNull);
    expect(AuthValidation.confirmation('password', 'password'), isNull);
  });
  test('server exceptions never expose raw details', () {
    expect(
      safeAuthMessage(const AuthException('secret token')),
      isNot(contains('secret')),
    );
    expect(
      safeAuthMessage(
        const AuthException('secret', code: 'email_not_confirmed'),
      ),
      contains('belum dikonfirmasi'),
    );
  });
  test('restores existing session without login or logout', () async {
    final auth = FakeAuth()..userId = 'existing';
    final controller = AuthController(auth);
    expect(controller.screen, AuthScreen.checking);
    await tick();
    expect(controller.screen, AuthScreen.authenticated);
    expect(auth.logins + auth.logouts, 0);
    controller.dispose();
    await auth.events.close();
  });
  test('expired or failed session cannot open protected content', () async {
    final auth = FakeAuth()
      ..userId = 'expired'
      ..error = Exception('private');
    final controller = AuthController(auth);
    await tick();
    expect(controller.screen, AuthScreen.sessionError);
    expect(auth.userId, 'expired');
    expect(controller.message, isNot(contains('private')));
    controller.dispose();
    await auth.events.close();
  });
  test(
    'account switch drops stale verification, logout removes access',
    () async {
      final pending = Completer<String>();
      final auth = FakeAuth()
        ..userId = 'old'
        ..verify = () => pending.future;
      final controller = AuthController(auth);
      auth.userId = 'new';
      auth.verify = () async => 'new';
      auth.events.add(AuthSignal.changed);
      await tick();
      expect(controller.screen, AuthScreen.authenticated);
      pending.complete('old');
      await tick();
      expect(auth.userId, 'new');
      expect(controller.screen, AuthScreen.authenticated);
      await controller.logout();
      expect(controller.screen, AuthScreen.welcome);
      controller.go(AuthScreen.authenticated);
      expect(controller.screen, AuthScreen.welcome);
      controller.dispose();
      await auth.events.close();
    },
  );
  test(
    'registration without session shows verification, with session verifies',
    () async {
      for (final immediate in [false, true]) {
        final auth = FakeAuth()..autoConfirm = immediate;
        final controller = AuthController(auth);
        await controller.submit('a@example.test', 'password', register: true);
        await tick();
        expect(
          controller.screen,
          immediate ? AuthScreen.authenticated : AuthScreen.verification,
        );
        controller.dispose();
        await auth.events.close();
      }
    },
  );
  test('duplicate submissions blocked and errors sanitized', () async {
    final pending = Completer<void>();
    final auth = FakeAuth();
    auth.action = () => pending.future;
    auth.error = const AuthException('sensitive');
    final controller = AuthController(auth);
    controller.go(AuthScreen.login);
    final first = controller.submit(
      'a@example.test',
      'password',
      register: false,
    );
    expect(controller.busy, true);
    await controller.submit('a@example.test', 'password', register: false);
    expect(auth.logins, 1);
    pending.complete();
    await first;
    expect(controller.busy, false);
    expect(controller.message, isNot(contains('sensitive')));
    controller.dispose();
    await auth.events.close();
  });
  test('recovery event never opens the protected shell', () async {
    final auth = FakeAuth()..userId = 'recovery';
    final controller = AuthController(auth);
    auth.events.add(AuthSignal.recovery);
    await tick();
    expect(controller.screen, AuthScreen.recovery);
    controller.dispose();
    await auth.events.close();
  });

  testWidgets('login fields, visibility, loading and failure state', (
    tester,
  ) async {
    final auth = FakeAuth();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.onboarding,
        home: AuthBoundary(gateway: auth),
      ),
    );
    await tester.tap(find.text('Sudah punya akun? Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(auth.logins, 0);
    await tester.enterText(find.byType(TextFormField).at(0), 'a@example.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      true,
    );
    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      false,
    );
    final pending = Completer<void>();
    auth.action = () => pending.future;
    auth.error = const AuthException('private');
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Memeriksa akun…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Autentikasi belum berhasil'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });
  testWidgets('registration checks confirmation and presents email status', (
    tester,
  ) async {
    final auth = FakeAuth();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.onboarding,
        home: AuthBoundary(gateway: auth),
      ),
    );
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'a@example.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.enterText(find.byType(TextFormField).at(2), 'wrong');
    await tester.ensureVisible(find.text('Buat akun'));
    await tester.tap(find.text('Buat akun'));
    await tester.pumpAndSettle();
    expect(auth.registrations, 0);
    expect(find.text('Konfirmasi kata sandi belum sama.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'password');
    await tester.ensureVisible(find.text('Buat akun'));
    await tester.tap(find.text('Buat akun'));
    await tester.pumpAndSettle();
    expect(find.text('Periksa emailmu'), findsOneWidget);
    expect(find.text('Ruang akademikmu'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });
  testWidgets('restored shell logout cannot navigate back into protected UI', (
    tester,
  ) async {
    final auth = FakeAuth()..userId = 'existing';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.onboarding,
        home: AuthBoundary(gateway: auth),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ruang akademikmu'), findsOneWidget);
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Ruang akademikmu'), findsNothing);
    expect(find.text('Daftar'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });
}
