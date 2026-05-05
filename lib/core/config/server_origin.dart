/// Origin (`scheme://host[:port]`) + pathname (`/wg`) for the panel behind reverse proxy / subpath.
abstract final class ServerOrigin {
  ServerOrigin._();

  /// Fallback origin when prefs are missing or a URL cannot be parsed (RFC 2606 placeholder — never a real deployment).
  static const defaultOrigin = 'https://example.com';

  /// Mount path for wireguard-ui and its `/api` routes.
  static const defaultBasePath = '/wg';

  /// `/wg`, `/`, `wg`, `/a/b/` → empty (UI root) or normalized `/path`.
  static String normalizeBasePath(String raw) {
    var p = raw.trim();
    if (p.isEmpty || p == '/') return '';
    if (!p.startsWith('/')) p = '/$p';
    while (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  /// Split a single URL (**`https://demo.net/peers`** → **`https://demo.net`** + **`/peers`**).
  ///
  /// If there is no **`://`**, a scheme is inferred: **`http://`** for bare **IPv4**,
  /// **localhost**, or **::1** (typical LAN panels without TLS); otherwise **`https://`**.
  /// To force a scheme, always include it (e.g. `http://10.0.0.1`, `https://vpn.example`).
  static ({String origin, String basePath}) splitUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) {
      return (origin: defaultOrigin, basePath: defaultBasePath);
    }

    if (!s.contains('://')) {
      final prefix = _bareInputPrefersHttp(s) ? 'http://' : 'https://';
      s = '$prefix$s';
    }

    Uri uri;
    try {
      uri = Uri.parse(s);
    } catch (_) {
      return (origin: defaultOrigin, basePath: defaultBasePath);
    }

    if (!uri.hasAuthority || uri.host.isEmpty) {
      return (origin: defaultOrigin, basePath: defaultBasePath);
    }

    final origin = uri.origin;
    final inferred = uri.path.isEmpty ? '' : normalizeBasePath(uri.path);
    return (origin: origin, basePath: inferred);
  }

  /// First path segment / authority before `/` (e.g. `192.168.1.5:5000` from `192.168.1.5:5000/wg`).
  static bool _bareInputPrefersHttp(String raw) {
    final firstSeg = raw.split('/').first.trim();
    if (firstSeg.isEmpty) return false;
    final authority = firstSeg.split('@').last;
    final host = _hostOnlyFromAuthority(authority);
    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
      return true;
    }
    return _isIPv4Literal(host);
  }

  static String _hostOnlyFromAuthority(String authority) {
    var a = authority.trim();
    if (a.startsWith('[')) {
      final end = a.indexOf(']');
      if (end != -1) return a.substring(1, end);
      return a;
    }
    final colon = a.lastIndexOf(':');
    if (colon > 0 && !a.contains(']')) {
      final tail = a.substring(colon + 1);
      if (int.tryParse(tail) != null) {
        return a.substring(0, colon);
      }
    }
    return a;
  }

  static bool _isIPv4Literal(String host) {
    return RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(host);
  }
}
