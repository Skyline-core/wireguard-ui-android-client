/// SharedPreferences keys and WorkManager task names for background HTTP health checks.
abstract final class ServerHealthConstants {
  ServerHealthConstants._();

  static const uniqueName = 'wgui_server_health_periodic';
  static const taskName = 'serverHealthCheck';

  /// Last probe outcome was OK (or unknown → treated as OK). When false, we already
  /// showed “unreachable” and stay silent until the server responds again.
  static const prefsPrevOk = 'wgui_health_prev_ok';

  /// Same notification id every time so Android replaces instead of stacking copies.
  static const unreachableNotificationId = 941001;

  /// Quick GET retries in one run (reduces false “down” from a single timeout / packet loss).
  static const probeAttempts = 3;
  static const probeRetryDelay = Duration(seconds: 2);
  static const connectTimeoutSeconds = 10;
}
