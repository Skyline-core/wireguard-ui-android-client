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
  /// If there is no **`://`**, **`https://`** is prepended.
  static ({String origin, String basePath}) splitUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) {
      return (origin: defaultOrigin, basePath: defaultBasePath);
    }

    if (!s.contains('://')) {
      s = 'https://$s';
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
}
