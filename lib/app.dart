import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          home: const SplashGate(),
        );
      },
    );
  }
}
