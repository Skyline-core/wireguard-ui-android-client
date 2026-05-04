/// Client-side session rules (independent of server `SESSION_MAX_DURATION`).
class SessionConstants {
  SessionConstants._();

  /// If no successful HTTP calls occur for this long, the local session is cleared.
  static const int idleLogoutDays = 15;
}
