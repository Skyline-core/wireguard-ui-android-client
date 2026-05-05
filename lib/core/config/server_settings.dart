import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'server_origin.dart';

/// Tema de la app: [system] sigue el modo claro/oscuro del dispositivo.
enum AppThemePreference { system, light, dark }

extension AppThemePreferenceMode on AppThemePreference {
  ThemeMode get themeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };
}

class ServerSettings extends ChangeNotifier {
  static const _urlKey = 'wgui_base_url';
  static const _pathKey = 'wgui_base_path';
  static const _trafficPeerChartKey = 'wgui_traffic_peer_chart';
  static const _passkeyOriginKey = 'wgui_passkey_public_origin';
  static const _themePreferenceKey = 'wgui_theme_preference';

  /// Empty until [load] runs; with no saved prefs, the panel is unconfigured (no placeholder network calls).
  String baseUrl = '';
  String basePath = '';

  /// Same HTTPS origin as the browser URL where passkeys were registered (e.g. `https://vpn.example.net`).
  /// Required when the API is reached by IP or another host than the WebAuthn rpId.
  String passkeyPublicOrigin = '';

  /// Traffic screen: stacked bars per peer (matches wireguard-ui web) vs aggregate time buckets.
  bool trafficChartPerPeer = false;

  /// Preferencia de tema (claro / oscuro / sistema).
  AppThemePreference themePreference = AppThemePreference.system;

  bool _loaded = false;

  bool get loaded => _loaded;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final hasUrlKey = p.containsKey(_urlKey);
    final hasPathKey = p.containsKey(_pathKey);

    if (!hasUrlKey && !hasPathKey) {
      baseUrl = '';
      basePath = '';
    } else {
      final rawUrl = hasUrlKey ? p.getString(_urlKey)! : ServerOrigin.defaultOrigin;

      late final String pathCandidate;
      if (hasPathKey) {
        pathCandidate = p.getString(_pathKey) ?? '';
      } else {
        final inferred = ServerOrigin.splitUrl(rawUrl).basePath;
        pathCandidate =
            inferred.isNotEmpty ? inferred : ServerOrigin.defaultBasePath;
      }

      final splitAgain = ServerOrigin.splitUrl(rawUrl);
      baseUrl = splitAgain.origin;
      basePath = ServerOrigin.normalizeBasePath(pathCandidate);
    }

    trafficChartPerPeer = p.getBool(_trafficPeerChartKey) ?? false;
    passkeyPublicOrigin = p.getString(_passkeyOriginKey) ?? '';
    themePreference = _parseThemePreference(p.getString(_themePreferenceKey));

    _loaded = true;
    notifyListeners();
  }

  AppThemePreference _parseThemePreference(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      case 'system':
      default:
        return AppThemePreference.system;
    }
  }

  Future<void> setThemePreference(AppThemePreference value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_themePreferenceKey, value.name);
    themePreference = value;
    notifyListeners();
  }

  ThemeMode get themeMode => themePreference.themeMode;

  Future<void> setTrafficChartPerPeer(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_trafficPeerChartKey, value);
    trafficChartPerPeer = value;
    notifyListeners();
  }

  String get originNormalized {
    var u = baseUrl.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// URL as typically pasted on login: **`https://host`** or **`https://host/wg`** (`BASE_PATH` optional).
  String get configuredPanelUrlDisplay {
    final origin = originNormalized;
    if (origin.isEmpty) return '';
    final path = basePath.trim();
    if (path.isEmpty) return origin;
    return '$origin${path.startsWith('/') ? path : '/$path'}';
  }

  /// `{origin}{basePath}` used as REST prefix (e.g. `https://host/wg` + `/login`).
  /// Empty when the user has not saved a panel URL yet ([load] with no prefs).
  String get apiPrefix {
    final origin = originNormalized;
    if (origin.isEmpty) return '';
    final path = ServerOrigin.normalizeBasePath(basePath);
    if (path.isEmpty) return origin;
    return '$origin$path';
  }

  /// Public HTTPS origin for WebAuthn challenges in the app; `null` when the header should not be sent.
  String? get passkeyOriginRequestHeaderValue {
    final t = passkeyPublicOrigin.trim();
    if (t.isEmpty) return null;
    if (t.contains('://')) return t;
    return 'https://$t';
  }

  /// [url]: origin **or** full URL with path (**`https://x/wg`** splits pathname).
  /// [path]: when non-empty, **overrides** the pathname inferred from [url].
  Future<void> save({
    required String url,
    required String path,
    required String passkeyPublicOrigin,
  }) async {
    final split = ServerOrigin.splitUrl(url);
    final userPathTrim = path.trim();
    final outPath = userPathTrim.isNotEmpty
        ? ServerOrigin.normalizeBasePath(userPathTrim)
        : split.basePath;

    final p = await SharedPreferences.getInstance();
    await p.setString(_urlKey, split.origin);
    await p.setString(_pathKey, outPath);

    final pko = passkeyPublicOrigin.trim();
    if (pko.isEmpty) {
      await p.remove(_passkeyOriginKey);
      this.passkeyPublicOrigin = '';
    } else {
      await p.setString(_passkeyOriginKey, pko);
      this.passkeyPublicOrigin = pko;
    }

    baseUrl = split.origin;
    basePath = outPath;

    if (kDebugMode) {
      debugPrint('[WGUI] apiPrefix="$apiPrefix"');
    }
    notifyListeners();
  }

  /// Updates only the base path; origin (`baseUrl`) stays as already stored in prefs.
  /// Schedules `notifyListeners` on the next frame to avoid chaining with other Providers in the same build.
  Future<void> savePathOnly(String path) async {
    final outPath = ServerOrigin.normalizeBasePath(path.trim());
    final p = await SharedPreferences.getInstance();
    await p.setString(_pathKey, outPath);
    basePath = outPath;
    if (kDebugMode) {
      debugPrint('[WGUI] apiPrefix="$apiPrefix" (path-only save)');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
