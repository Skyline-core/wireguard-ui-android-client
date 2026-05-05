import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'server_health_constants.dart';
import 'server_health_worker.dart';

/// Registers the periodic task only when a local session is active ([AuthStore] `ready`).
abstract final class ServerHealthScheduler {
  ServerHealthScheduler._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_initialized) return;
    _initialized = true;
    await Workmanager().initialize(serverHealthCallbackDispatcher);
  }

  /// [activeSession]: remembered, valid in-app session (same idea as using the web panel).
  static Future<void> syncRegistration(bool activeSession) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    if (!activeSession) {
      await _clearHealthPrefs();
      await Workmanager().cancelByUniqueName(ServerHealthConstants.uniqueName);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final recall = prefs.getBool('wgui_session_recall') ?? false;
    if (!recall) {
      await Workmanager().cancelByUniqueName(ServerHealthConstants.uniqueName);
      return;
    }

    await Workmanager().registerPeriodicTask(
      ServerHealthConstants.uniqueName,
      ServerHealthConstants.taskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> _clearHealthPrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(ServerHealthConstants.prefsPrevOk);
  }
}
