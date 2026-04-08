import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'flavor/app_flavor.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import '../features/home/presentation/home_shell_screen.dart';

class MfCalcApp extends StatelessWidget {
  const MfCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppFlavor.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShellScreen(),
    );
  }
}
