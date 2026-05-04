import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_reload_signal.dart';
import 'core/config/server_settings.dart';
import 'core/session/auth_store.dart';
import 'core/wg_apply_controller.dart';
import 'background/server_health_scheduler.dart';
import 'notifications/fcm_background.dart';
import 'notifications/wgu_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerHealthScheduler.initialize();

  final serverCfg = ServerSettings();
  await serverCfg.load();

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Firebase init: $e');
    }
  }
  final alerts = await WguNotificationController.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => serverCfg),
        ChangeNotifierProvider(create: (_) => AuthStore()),
        ChangeNotifierProvider(create: (_) => WgApplyController()),
        ChangeNotifierProvider(create: (_) => AppReloadSignal()),
        ChangeNotifierProvider<WguNotificationController>.value(value: alerts),
      ],
      child: const WireguardUiApp(),
    ),
  );
}
