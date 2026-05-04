import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/config/server_origin.dart';
import '../core/theme/app_theme.dart';
import '../notifications/wgu_notifications.dart';
import 'server_health_constants.dart';

/// Same preference key as [AuthStore].
const _kSessionRecall = 'wgui_session_recall';
const _kUrlKey = 'wgui_base_url';
const _kPathKey = 'wgui_base_path';

@pragma('vm:entry-point')
void serverHealthCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != ServerHealthConstants.taskName) {
      return true;
    }
    await ServerHealthWorker.run();
    return true;
  });
}

/// Lightweight cookie-less GET; any HTTP response means the server is reachable.
abstract final class ServerHealthWorker {
  ServerHealthWorker._();

  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    final recall = prefs.getBool(_kSessionRecall) ?? false;
    if (!recall) {
      return;
    }

    final apiPrefix = _apiPrefixFromPrefs(prefs);
    if (apiPrefix.isEmpty) {
      return;
    }
    var reachable = false;
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          validateStatus: (c) => c != null && c > 0,
          followRedirects: true,
          maxRedirects: 8,
          responseType: ResponseType.plain,
        ),
      );
      await dio.get<dynamic>(
        '${_normalizePrefix(apiPrefix)}/api/ui-nav-hints',
      );
      reachable = true;
    } catch (_) {
      reachable = false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final prevOk = prefs.getBool(ServerHealthConstants.prefsPrevOk) ?? true;

    if (reachable) {
      await prefs.setBool(ServerHealthConstants.prefsPrevOk, true);
      return;
    }

    if (prevOk) {
      await _showUnreachableNotification();
      await prefs.setBool(ServerHealthConstants.prefsPrevOk, false);
      await prefs.setInt(ServerHealthConstants.prefsLastNotifyMs, now);
      return;
    }

    final lastNotify = prefs.getInt(ServerHealthConstants.prefsLastNotifyMs) ?? 0;
    if (now - lastNotify >= ServerHealthConstants.throttleRepeatMs) {
      await _showUnreachableNotification();
      await prefs.setInt(ServerHealthConstants.prefsLastNotifyMs, now);
    }
  }

  static Future<void> _showUnreachableNotification() async {
    const androidInit =
        AndroidInitializationSettings('ic_wireguard_notification');
    const init = InitializationSettings(android: androidInit);
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(init);

    final android = plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        kWguAlertsChannelId,
        'WireGuard UI',
        description: 'Client and server alerts',
        importance: Importance.defaultImportance,
      ),
    );

    await plugin.show(
      941001,
      'Cannot reach panel',
      'Your WireGuard UI server is unreachable. Check network or the panel.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          kWguAlertsChannelId,
          'WireGuard UI',
          channelDescription: 'Client and server alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: AppColors.accent,
        ),
      ),
    );
  }

  static String _normalizePrefix(String apiPrefix) {
    var u = apiPrefix.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Mirrors [ServerSettings.load] for the background isolate (no Provider context).
  static String _apiPrefixFromPrefs(SharedPreferences p) {
    final hasUrl = p.containsKey(_kUrlKey);
    final hasPath = p.containsKey(_kPathKey);

    if (!hasUrl && !hasPath) {
      return '';
    }

    final rawUrl = hasUrl ? p.getString(_kUrlKey)! : ServerOrigin.defaultOrigin;

    late final String pathCandidate;
    if (hasPath) {
      pathCandidate = p.getString(_kPathKey) ?? '';
    } else {
      final inferred = ServerOrigin.splitUrl(rawUrl).basePath;
      pathCandidate =
          inferred.isNotEmpty ? inferred : ServerOrigin.defaultBasePath;
    }

    final splitAgain = ServerOrigin.splitUrl(rawUrl);
    final origin = splitAgain.origin;
    final path = ServerOrigin.normalizeBasePath(pathCandidate);
    return _joinPrefix(origin, path);
  }

  static String _joinPrefix(String origin, String path) {
    var o = origin.trim();
    while (o.endsWith('/')) {
      o = o.substring(0, o.length - 1);
    }
    final p = ServerOrigin.normalizeBasePath(path);
    if (p.isEmpty) return o;
    return '$o$p';
  }
}
