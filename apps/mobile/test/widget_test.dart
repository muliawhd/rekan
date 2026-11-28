import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:re_mobile/app.dart';
import 'package:re_mobile/core/widgets/rekan_logo.dart';
import 'package:re_mobile/features/auth/auth_gateway.dart';

class _TestAuthGateway implements AuthGateway {
  @override
  String? userId;
  final _ctrl = StreamController<AuthSignal>.broadcast();
  @override
  Stream<AuthSignal> get changes => _ctrl.stream;
  @override
  Future<String> verifySession() async => userId!;
  @override
  Future<void> login(String email, String password) async {}
  @override
  Future<void> register(String email, String password) async {}
  @override
  Future<void> logout() async {}
  void dispose() => _ctrl.close();
}

void main() {
  testWidgets(
    'app starts on SplashScreen with centered logo then opens Login with Register below',
    (tester) async {
      final gw = _TestAuthGateway();
      addTearDown(gw.dispose);

      await tester.pumpWidget(
        ReApp(
          splashDuration: const Duration(milliseconds: 200),
          authGatewayOverride: gw,
        ),
      );

      expect(find.text('Memuat ruang kolaborasi...'), findsOneWidget);
      expect(find.byType(RekanLogo), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Selamat Datang Kembali!'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Belum punya akun?'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
