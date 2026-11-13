import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245C45)),
    useMaterial3: true,
  );
}
