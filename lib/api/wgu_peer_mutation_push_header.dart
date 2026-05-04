/// FCM registration token sent on POSTs that mutate peers so wireguard-ui can skip pushing to [registeredFcmToken] (same device).
class WguPeerMutationPushHeader {
  WguPeerMutationPushHeader._();

  /// Must match pushnotify.HeaderXWGUIFCMToken (`X-WGUI-FCM-Token`).
  static const headerName = 'X-WGUI-FCM-Token';

  /// Set when FCM registration with the server succeeds; cleared on logout/disable.
  static String? registeredFcmToken;
}

bool wguRequestsPeerMutationFcmSkip(String method, Uri uri) {
  if (method.toUpperCase() != 'POST') return false;
  var p = uri.path;
  while (p.endsWith('/')) {
    if (p.isEmpty || p.length == 1) break;
    p = p.substring(0, p.length - 1);
  }
  return p.endsWith('/new-client') ||
      p.endsWith('/client/set-status') ||
      p.endsWith('/remove-client');
}
