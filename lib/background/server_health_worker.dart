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
    final apiUrl =
        '${_normalizePrefix(apiPrefix)}/api/ui-nav-hints';
    final reachable = await _probeReachable(apiUrl);

    final prevOk = prefs.getBool(ServerHealthConstants.prefsPrevOk) ?? true;

    if (reachable) {
      if (!prevOk) {
        await _cancelUnreachableNotification();
      }
      await prefs.setBool(ServerHealthConstants.prefsPrevOk, true);
      return;
    }

    // Still down: notify at most once per outage (transition OK → fail only).
    if (prevOk) {
      await _showUnreachableNotification();
      await prefs.setBool(ServerHealthConstants.prefsPrevOk, false);
    }
  }

  /// Several attempts in one worker run to avoid false positives from a single
  /// timeout, DNS blip, or packet loss on mobile networks.
  static Future<bool> _probeReachable(String url) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: Duration(
          seconds: ServerHealthConstants.connectTimeoutSeconds,
        ),
        sendTimeout: Duration(
          seconds: ServerHealthConstants.connectTimeoutSeconds,
        ),
        receiveTimeout: Duration(
          seconds: ServerHealthConstants.connectTimeoutSeconds,
        ),
        validateStatus: (c) => c != null && c > 0,
        followRedirects: true,
        maxRedirects: 8,
        responseType: ResponseType.plain,
      ),
    );
    for (var attempt = 0;
        attempt < ServerHealthConstants.probeAttempts;
        attempt++) {
      try {
        await dio.get<dynamic>(url);
        return true;
      } catch (_) {
        if (attempt < ServerHealthConstants.probeAttempts - 1) {
          await Future<void>.delayed(ServerHealthConstants.probeRetryDelay);
        }
      }
    }
    return false;
  }

  static Future<void> _cancelUnreachableNotification() async {
    const androidInit =
        AndroidInitializationSettings('ic_wireguard_notification');
    const init = InitializationSettings(android: androidInit);
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(init);
    await plugin.cancel(ServerHealthConstants.unreachableNotificationId);
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
      ServerHealthConstants.unreachableNotificationId,
      'Cannot reach panel',
      'Your WireGuard UI server is unreachable. Check network or the panel.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          kWguAlertsChannelId,
          'WireGuard UI',
          channelDescription: 'Client and server alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: kAppAccentColor,
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
