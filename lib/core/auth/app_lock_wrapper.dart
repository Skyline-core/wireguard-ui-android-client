import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../config/server_settings.dart';

class AppLockWrapper extends StatefulWidget {
  const AppLockWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isLocked = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final isEnabled = context.read<ServerSettings>().appLockEnabled;
      if (isEnabled && !_isLocked) {
        setState(() => _isLocked = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked) {
        _authenticate();
      }
    }
  }

  Future<void> _checkLockStatus() async {
    final isEnabled = context.read<ServerSettings>().appLockEnabled;
    if (isEnabled) {
      setState(() => _isLocked = true);
      await _authenticate();
    }
  }

  Future<void> _authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: AppLocalizations.of(context)!.appUnlockPrompt,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
      if (authenticated && mounted) {
        setState(() => _isLocked = false);
      }
    } catch (e) {
      // Ignore errors (e.g. cancelled), keeps it locked
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.appLockedTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _authenticate,
                      child: Text(AppLocalizations.of(context)!.appUnlockButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
