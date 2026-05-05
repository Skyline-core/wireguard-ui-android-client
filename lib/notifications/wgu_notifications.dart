import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/wgu_peer_mutation_push_header.dart';
import '../api/wgu_repository.dart';
import '../core/config/server_settings.dart';
import '../core/theme/app_theme.dart';
import '../core/session/auth_store.dart';

const _kAlertsKey = 'wgui_local_notifications';

/// Shared channel (FCM, WorkManager health checks, etc.).
const kWguAlertsChannelId = 'wgui_alerts';

/// FCM push from wireguard-ui plus a local notification when the app is in foreground.
/// The server rate-limits deliveries (e.g. per token per minute).
class WguNotificationController extends ChangeNotifier {
  WguNotificationController({required this.prefs});

  final SharedPreferences prefs;
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  bool enabled = false;

  /// FCM token registered on the server while the session is valid.
  bool pushReady = false;

  WguRepository? _repoFactory;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  String? _registeredToken;

  bool get _nativePushSupported =>
      defaultTargetPlatform == TargetPlatform.android;

  static Future<WguNotificationController> create() async {
    final p = await SharedPreferences.getInstance();
    final c = WguNotificationController(prefs: p);
    await c.initialize();
    return c;
  }

  Future<void> initialize() async {
    const androidInit =
        AndroidInitializationSettings('ic_wireguard_notification');
    const init = InitializationSettings(android: androidInit);
    await plugin.initialize(init);

    final android =
        plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        kWguAlertsChannelId,
        'WireGuard UI',
        description: 'Push alerts from the server',
        importance: Importance.defaultImportance,
      ),
    );
    enabled = prefs.getBool(_kAlertsKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(AuthStore auth, ServerSettings cfg, bool v) async {
    enabled = v;
    await prefs.setBool(_kAlertsKey, v);
    _repoFactory = WguRepository.fromContext(auth, cfg);

    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;

    if (!v) {
      final token = _registeredToken;
      final repo = _repoFactory;
      if (token != null && token.isNotEmpty && repo != null) {
        try {
          await repo.unregisterPushToken(token);
        } catch (_) {}
      }
      _registeredToken = null;
      WguPeerMutationPushHeader.registeredFcmToken = null;
      pushReady = false;
      notifyListeners();
      return;
    }

    notifyListeners();
    if (!_nativePushSupported) {
      debugPrint('[WGU] FCM push is Android-only when Firebase is configured.');
      return;
    }
    if (auth.offlineMode) {
      debugPrint('[WGU] Offline: FCM will register when the server is reachable again.');
      return;
    }
    await _startPushPipeline();
  }

  /// Call before [AuthStore.logout] to revoke the token on the server.
  Future<void> prepareLogout(AuthStore auth, ServerSettings cfg) async {
    _repoFactory = WguRepository.fromContext(auth, cfg);
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;

    final token = _registeredToken;
    final repo = _repoFactory;
    if (token != null && token.isNotEmpty && repo != null) {
      try {
        await repo.unregisterPushToken(token);
      } catch (_) {}
    }
    _registeredToken = null;
    WguPeerMutationPushHeader.registeredFcmToken = null;
    pushReady = false;
    notifyListeners();
  }

  Future<void> _startPushPipeline() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('[WGU] Firebase no inicializado: $e');
        return;
      }
    }

    final messaging = FirebaseMessaging.instance;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[WGU] Sin token FCM');
      return;
    }

    final repo = _repoFactory;
    if (repo == null) return;

    final ok = await repo.registerPushToken(token: token, platform: 'android');
    if (!ok) {
      debugPrint('[WGU] registerPushToken failed');
      return;
    }
    _registeredToken = token;
    WguPeerMutationPushHeader.registeredFcmToken = token;
    pushReady = true;
    notifyListeners();

    _onMessageSub = FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      final title = n?.title ?? m.data['title']?.toString() ?? 'WireGuard UI';
      final body = n?.body ?? m.data['body']?.toString() ?? '';
      unawaited(_show(title, body));
    });

    _onTokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
      final r = _repoFactory;
      if (r == null) return;
      final reg = await r.registerPushToken(token: newToken, platform: 'android');
      if (reg) {
        _registeredToken = newToken;
        WguPeerMutationPushHeader.registeredFcmToken = newToken;
      }
    });
  }

  Future<void> _show(String title, String body) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('[WireGuard UI] $title · $body');
      return;
    }
    await plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kWguAlertsChannelId,
          'WireGuard UI',
          channelDescription: 'Push alerts from the server',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: kAppAccentColor,
        ),
      ),
    );
  }

}
