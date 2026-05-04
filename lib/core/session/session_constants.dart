/// Client-side session rules: offline stash + bootstrap discard after no activity.
///
/// The Android build also identifies with header `X-WGUI-Client: android` so the server applies at
/// least this many days of **sliding idle** while browsers keep using admin **Session idle timeout**
/// (minutes) only.
class SessionConstants {
  SessionConstants._();

  /// Must match server `androidCompanionIdleMinSeconds` (wireguard-ui `handler/session.go`).
  static const int idleLogoutDays = 15;
}
