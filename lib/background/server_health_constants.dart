/// SharedPreferences keys and WorkManager task names for background HTTP health checks.
abstract final class ServerHealthConstants {
  ServerHealthConstants._();

  static const uniqueName = 'wgui_server_health_periodic';
  static const taskName = 'serverHealthCheck';

  static const prefsPrevOk = 'wgui_health_prev_ok';
  static const prefsLastNotifyMs = 'wgui_health_last_notify_ms';

  /// Minimum gap between repeated “still down” notifications (Android may run the task about every 15 min).
  static const throttleRepeatMs = 24 * 60 * 60 * 1000;
}
