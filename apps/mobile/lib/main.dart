import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/auth/initialize_auth.dart';
import 'core/theme/rekan_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeAuth();
    runApp(const ReApp());
  } catch (_) {
    // Do not log/render SDK exceptions that might contain sensitive values.
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: RekanPalette.themeData,
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Layanan akun belum dapat disiapkan. Tutup dan buka kembali Re:kan untuk mencoba lagi.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
