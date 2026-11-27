 import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/auth/initialize_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeAuth();
    runApp(const ReApp());
  } catch (_) {
    // Do not log/render SDK exceptions that might contain sensitive values.
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Layanan akun belum dapat disiapkan. Tutup dan buka kembali Re:kan untuk mencoba lagi.',
            ),
          ),
        ),
      ),
    );
  }
}
