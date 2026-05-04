import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/exceptions.dart' as pkex;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../background/server_health_scheduler.dart';
import '../../api/wgu_http.dart';
import '../../api/wgu_repository.dart';
import '../auth/passkey_options.dart';
import '../config/server_settings.dart';
import '../offline/offline_snapshot_store.dart';
import 'session_constants.dart';

/// Same header as wireguard-ui [util.WebAuthnPublicOriginHeader].
const _kWebAuthnPublicOriginHeader = 'X-WGUI-WebAuthn-Public-Origin';

class AuthStore extends ChangeNotifier {
  static const _kLastActivityMs = 'wgui_last_activity_ms';
  static const _kSessionRecall = 'wgui_session_recall';

  String? username;
  String? _dioError;
  bool checked = false;
  bool ready = false;

  /// No HTTP response from the server, but the local session is still valid (cookies + activity).
  bool offlineMode = false;

  WireguardHttpClient? http;
  CookieJar? _cookieJar;
  bool _hooksInstalled = false;

  String? get lastError => _dioError;

  Future<CookieJar> _jar() async {
    if (_cookieJar != null) return _cookieJar!;
    _cookieJar = PersistCookieJar(
      storage: FileStorage(
        '${(await getApplicationDocumentsDirectory()).path}/.wgui_cookies',
      ),
    );
    return _cookieJar!;
  }

  void _disposeHttpInstance() {
    try {
      http?.dispose();
    } catch (_) {}
    http = null;
    _hooksInstalled = false;
  }

  Future<void> _persistSessionMarkers() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSessionRecall, true);
    await _touchActivityPrefs(p);
  }

  Future<void> _touchActivityPrefs([SharedPreferences? existing]) async {
    final p = existing ?? await SharedPreferences.getInstance();
    await p.setInt(
      _kLastActivityMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _touchActivity() => _touchActivityPrefs();

  Future<bool> _idleSessionExpired() async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt(_kLastActivityMs);
    if (ms == null) return false;
    final last = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.now().difference(last).inDays >= SessionConstants.idleLogoutDays;
  }

  Future<void> _localLogoutClearPrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSessionRecall);
    await p.remove(_kLastActivityMs);
    await OfflineSnapshotStore.clear();
  }

  Future<void> _logoutLocalOnly() async {
    offlineMode = false;
    username = null;
    ready = false;
    _disposeHttpInstance();
    try {
      await _cookieJar?.deleteAll();
    } catch (_) {}
    await _localLogoutClearPrefs();
  }

  void _registerDioSessionHooks() {
    if (http == null || _hooksInstalled) return;
    _hooksInstalled = true;
    http!.dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (r, h) {
          final c = r.statusCode;
          if (c != null && c >= 200 && c < 300) {
            unawaited(_touchActivity());
          }
          return h.next(r);
        },
        onError: (e, h) {
          _maybeEnterOffline(e);
          return h.next(e);
        },
      ),
    );
  }

  void _maybeEnterOffline(DioException e) {
    if (!ready || offlineMode) return;
    if (!_isUnreachableError(e)) return;
    offlineMode = true;
    notifyListeners();
  }

  /// Proxy/nginx in front of a down server often returns 502/503/504 (not an invalid session).
  bool _isUpstreamOrGatewayStatus(int? code) {
    if (code == null) return false;
    return code == 502 || code == 503 || code == 504;
  }

  bool _isUnreachableError(DioException e) {
    if (e.type == DioExceptionType.badResponse &&
        _isUpstreamOrGatewayStatus(e.response?.statusCode)) {
      return true;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        return e.error is SocketException || e.error is HandshakeException;
      default:
        return false;
    }
  }

  bool _bootstrapUnreachable(Object e) {
    if (e is DioException) return _isUnreachableError(e);
    if (e is SocketException) return true;
    return false;
  }

  Future<void> bootstrap(ServerSettings cfg) async {
    _dioError = null;
    offlineMode = false;

    if (await _idleSessionExpired()) {
      await _logoutLocalOnly();
      checked = true;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final recall = prefs.getBool(_kSessionRecall) ?? false;
    final lastMs = prefs.getInt(_kLastActivityMs);

    _disposeHttpInstance();
    if (cfg.apiPrefix.isEmpty) {
      checked = true;
      notifyListeners();
      return;
    }
    try {
      http = WireguardHttpClient(cfg.apiPrefix);
      await http!.initCookies(await _jar());
      _registerDioSessionHooks();

      final res = await http!.dio.get<dynamic>(
        '${cfg.apiPrefix}/api/clients',
        options: Options(
          followRedirects: true,
          maxRedirects: 8,
          validateStatus: (c) => c != null && c > 0,
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 40),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final code = res.statusCode;
      if (code == 302 || code == 301) {
        ready = false;
      } else if (code == 200) {
        final body = res.data?.toString() ?? '';
        final ct = res.headers.map['content-type']?.join(';') ?? '';
        ready =
            ct.contains('json') || body.trimLeft().startsWith('[');
      } else if (code == 401 || code == 403) {
        ready = false;
      } else if (_isUpstreamOrGatewayStatus(code) &&
          recall &&
          lastMs != null &&
          !await _idleSessionExpired()) {
        ready = true;
        offlineMode = true;
        _dioError = null;
      } else {
        ready = false;
        _dioError = 'HTTP $code';
      }

      if (ready) {
        offlineMode = false;
        await _persistSessionMarkers();
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        await _logoutLocalOnly();
      } else if (_isUnreachableError(e) &&
          recall &&
          lastMs != null &&
          !await _idleSessionExpired()) {
        ready = true;
        offlineMode = true;
        _dioError = null;
      } else {
        ready = false;
        offlineMode = false;
        _dioError = e.message ?? '$e';
      }
    } catch (e) {
      if (_bootstrapUnreachable(e) &&
          recall &&
          lastMs != null &&
          !await _idleSessionExpired()) {
        ready = true;
        offlineMode = true;
        _dioError = null;
      } else {
        ready = false;
        offlineMode = false;
        _dioError = '$e';
      }
    } finally {
      if (ready && http != null && !offlineMode) {
        try {
          final r = WguRepository(http!.dio, cfg.apiPrefix);
          final snap = await r.fetchProfilePasskeysSnapshot();
          if (snap.username.isNotEmpty) {
            username = snap.username;
          }
        } catch (_) {}
      } else if (ready && offlineMode && (username == null || username!.isEmpty)) {
        final snap = await OfflineSnapshotStore.load();
        if (snap?.username != null && snap!.username!.isNotEmpty) {
          username = snap.username;
        }
      }
      checked = true;
      notifyListeners();
    }
  }

  /// Lightweight GET; on success leaves offline mode and refreshes UI data.
  Future<bool> tryReconnect(ServerSettings cfg) async {
    if (!ready || http == null || !offlineMode) return false;
    try {
      final r = await http!.dio.get<dynamic>(
        '${cfg.apiPrefix}/api/ui-nav-hints',
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );
      if (r.statusCode == 200 && r.data is Map) {
        offlineMode = false;
        await _touchActivity();
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> login(
    ServerSettings cfg, {
    required String user,
    required String password,
    required bool remember,
  }) async {
    _dioError = null;
    offlineMode = false;

    final optBase = Options(
      followRedirects: true,
      maxRedirects: 8,
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 55),
    );

    try {
      _disposeHttpInstance();
      http = WireguardHttpClient(cfg.apiPrefix);
      await http!.initCookies(await _jar());
      _registerDioSessionHooks();

      await http!.dio.post<dynamic>(
        '${cfg.apiPrefix}/login',
        data: jsonEncode({
          'username': user,
          'password': password,
          'rememberMe': remember,
        }),
        options: optBase.copyWith(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      final probe = await http!.dio.get<dynamic>(
        '${cfg.apiPrefix}/api/clients',
        options: optBase.copyWith(
          validateStatus: (s) => s != null && s > 0,
          responseType: ResponseType.plain,
        ),
      );

      username = user;
      final body = probe.data?.toString() ?? '';
      final ok = probe.statusCode == 200 && !body.trimLeft().startsWith('<');
      ready = ok;
      if (!ok) {
        _dioError =
            probe.statusCode == 302 ? 'Sesión no establecida' : 'Credenciales';
      } else {
        await _persistSessionMarkers();
      }
    } on DioException catch (e) {
      _dioError = e.response?.data is Map
          ? '${(e.response!.data as Map)['message'] ?? e.message}'
          : e.message ?? '$e';
      ready = false;
    } catch (e) {
      _dioError = '$e';
      ready = false;
    } finally {
      notifyListeners();
    }

    return ready;
  }

  Future<bool> loginWithPasskey(
    ServerSettings cfg, {
    required bool remember,
    String? usernameHint,
  }) async {
    _dioError = null;
    offlineMode = false;

    final optBase = Options(
      followRedirects: true,
      maxRedirects: 8,
      sendTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 70),
    );

    try {
      _disposeHttpInstance();
      http = WireguardHttpClient(cfg.apiPrefix);
      await http!.initCookies(await _jar());
      _registerDioSessionHooks();
      final dio = http!.dio;

      final uh = usernameHint?.trim();
      final beginBody =
          (uh != null && uh.isNotEmpty) ? <String, dynamic>{'username': uh} : <String, dynamic>{};

      final passkeyHeaders = <String, String>{
        'Content-Type': 'application/json',
        if (cfg.passkeyOriginRequestHeaderValue != null)
          _kWebAuthnPublicOriginHeader: cfg.passkeyOriginRequestHeaderValue!,
      };

      final beginRes = await dio.post<dynamic>(
        '${cfg.apiPrefix}/api/passkeys/login/begin',
        data: jsonEncode(beginBody),
        options: optBase.copyWith(
          headers: passkeyHeaders,
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      final bCode = beginRes.statusCode ?? 0;
      if (bCode != 200) {
        final msg = beginRes.data is Map
            ? '${(beginRes.data as Map)['message'] ?? 'HTTP $bCode'}'
            : 'HTTP $bCode';
        _dioError = msg;
        ready = false;
        notifyListeners();
        return false;
      }

      final beginMap = Map<String, dynamic>.from(beginRes.data as Map);
      final req = parsePasskeyBeginOptions(beginMap);
      final assertion = await PasskeyAuthenticator().authenticate(req);

      final finishMap = <String, dynamic>{
        'rememberMe': remember,
        ...assertion.toJson(),
      };
      if (uh != null && uh.isNotEmpty) {
        finishMap['username'] = uh;
      }

      final finishRes = await dio.post<dynamic>(
        '${cfg.apiPrefix}/api/passkeys/login/finish',
        data: jsonEncode(finishMap),
        options: optBase.copyWith(
          headers: passkeyHeaders,
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      final fCode = finishRes.statusCode ?? 0;
      final fd = finishRes.data;
      if (fCode != 200 || (fd is Map && fd['status'] != true)) {
        final msg = fd is Map
            ? '${fd['message'] ?? 'Passkey inválida'}'
            : 'Error de sesión (HTTP $fCode)';
        _dioError = msg;
        ready = false;
        notifyListeners();
        return false;
      }

      final probe = await dio.get<dynamic>(
        '${cfg.apiPrefix}/api/clients',
        options: optBase.copyWith(
          validateStatus: (s) => s != null && s > 0,
          responseType: ResponseType.plain,
        ),
      );

      final body = probe.data?.toString() ?? '';
      final ok = probe.statusCode == 200 && !body.trimLeft().startsWith('<');
      ready = ok;
      if (!ok) {
        _dioError =
            probe.statusCode == 302 ? 'Sesión no establecida' : 'Sesión no válida tras passkey';
      } else {
        await _persistSessionMarkers();
        try {
          final r = WguRepository(dio, cfg.apiPrefix);
          final snap = await r.fetchProfilePasskeysSnapshot();
          if (snap.username.isNotEmpty) {
            username = snap.username;
          } else if (uh != null && uh.isNotEmpty) {
            username = uh;
          }
        } catch (_) {
          if (uh != null && uh.isNotEmpty) {
            username = uh;
          }
        }
      }
    } on DioException catch (e) {
      _dioError = e.response?.data is Map
          ? '${(e.response!.data as Map)['message'] ?? e.message}'
          : e.message ?? '$e';
      ready = false;
    } on pkex.PasskeyAuthCancelledException {
      _dioError = null;
      ready = false;
    } on pkex.NoCredentialsAvailableException {
      _dioError =
          'Android no encontró credenciales para este sitio (rpId/origen distinto '
          'o solo en la nube). Si entras por IP/LAN pero la passkey es del dominio HTTPS '
          'del panel, configura «Origen passkey» en pantalla de login con esa URL HTTPS. '
          'O usa usuario/contraseña.';
      ready = false;
    } on pkex.DomainNotAssociatedException catch (e) {
      _dioError =
          'La app no está vinculada al dominio del servidor para passkeys (${e.message ?? 'Digital Asset Links / dominios asociados'}). '
          'Puedes iniciar sesión con contraseña o usar el navegador.';
      ready = false;
    } on pkex.DeviceNotSupportedException {
      _dioError = 'Este dispositivo no admite passkeys.';
      ready = false;
    } on pkex.AuthenticatorException catch (e) {
      _dioError = e.toString();
      ready = false;
    } catch (e) {
      final s = '$e';
      if (s.contains('RP ID cannot be validated')) {
        _dioError =
            'Android no pudo validar el dominio de la passkey (rpId). Comprueba: '
            '(1) que exista https://<tu-dominio>/.well-known/assetlinks.json en la raíz del host '
            '(si el proxy solo enruta /wg, expón también /.well-known hacia wireguard-ui); '
            '(2) WGUI_ANDROID_PASSKEY_SHA256 coincide con la firma de esta build (./gradlew signingReport); '
            '(3) «Origen passkey» es el mismo host HTTPS donde creaste la passkey en el navegador. '
            'Detalle técnico: $s';
      } else {
        _dioError = s;
      }
      ready = false;
    } finally {
      notifyListeners();
    }

    return ready;
  }

  void syncSessionUsername(String name) {
    username = name;
    notifyListeners();
  }

  Future<void> logout(ServerSettings cfg) async {
    try {
      if (!offlineMode) {
        await http?.dio.get(
          '${cfg.apiPrefix}/logout',
          options: Options(
            followRedirects: false,
            validateStatus: (s) => s != null,
          ),
        );
      }
    } catch (_) {}
    offlineMode = false;
    username = null;
    ready = false;
    checked = true;
    try {
      await _cookieJar?.deleteAll();
    } catch (_) {}
    _disposeHttpInstance();
    await _localLogoutClearPrefs();
    unawaited(ServerHealthScheduler.syncRegistration(false));
    notifyListeners();
  }
}
