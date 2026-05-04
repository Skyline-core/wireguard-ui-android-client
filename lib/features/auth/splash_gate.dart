import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../background/server_health_scheduler.dart';
import '../../core/config/server_settings.dart';
import '../../core/session/auth_store.dart';
import 'login_screen.dart';
import '../shell/main_shell.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (!mounted) return;
    final cfg = context.read<ServerSettings>();
    final auth = context.read<AuthStore>();
    if (!cfg.loaded) await cfg.load();
    await auth.bootstrap(cfg);
    unawaited(ServerHealthScheduler.syncRegistration(auth.ready));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    // Spinner only: the icon was already shown on the native splash screen (Android 12+).
    // Repeating the SVG in Flutter used black fill and looked like a clipped/invisible second logo.
    if (_busy || !auth.checked) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return auth.ready ? const MainShell() : const LoginScreen();
  }
}
