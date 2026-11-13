import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/foundation/presentation/foundation_page.dart';

class ReApp extends StatelessWidget {
  const ReApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const FoundationPage(),
    );
  }
}
