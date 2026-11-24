import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:re_mobile/core/config/app_config.dart';
import 'package:re_mobile/features/auth_validation/development_api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android reaches host API and rejects missing/invalid tokens', (
    tester,
  ) async {
    expect(
      await DevelopmentApi(AppConfig.apiBaseUrl).checkGuestBoundary(),
      isTrue,
    );
  });
}
