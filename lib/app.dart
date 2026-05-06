import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/auth/app_lock_wrapper.dart';
import 'core/config/server_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_gate.dart';

class WireguardUiApp extends StatelessWidget {
  const WireguardUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerSettings>(
      builder: (context, cfg, _) {
        return MaterialApp(
          title: 'WireGuard UI',
          debugShowCheckedModeBanner: false,
          theme: buildAppLightTheme(),
          darkTheme: buildAppDarkTheme(),
          themeMode: cfg.themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: cfg.localePreference == AppLocalePreference.system
              ? null
              : Locale(cfg.localePreference.name),
          home: const AppLockWrapper(child: SplashGate()),
        );
      },
    );
  }
}
