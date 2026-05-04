import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_gate.dart';

class WireguardUiApp extends StatelessWidget {
  const WireguardUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WireGuard UI',
      debugShowCheckedModeBanner: false,
      theme: buildAppDarkTheme(),
      home: const SplashGate(),
    );
  }
}
