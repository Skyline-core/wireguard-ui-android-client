import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

import '../core/config/server_origin.dart';
import '../core/config/server_settings.dart';
import '../core/session/auth_store.dart';
import 'models/client_models.dart';
import 'models/dashboard_stats.dart';
import 'models/system_logs.dart';
import 'models/traffic_series.dart';
import 'models/profile_models.dart';

/// Same header as wireguard-ui `util.WebAuthnPublicOriginHeader` / [AuthStore] passkey login.
const _kWebAuthnPublicOriginHeader = 'X-WGUI-WebAuthn-Public-Origin';

/// REST access to wireguard-ui handlers registered in [`main.go`](../../wireguard-ui/main.go).
class WguRepository {
  WguRepository(this._dio, this.apiPrefix);

  final Dio _dio;
  final String apiPrefix;

  factory WguRepository.fromContext(AuthStore auth, ServerSettings cfg) {
    return WguRepository(auth.http!.dio, cfg.apiPrefix);
  }

  String _u(String rel) {
    final base = apiPrefix.endsWith('/')
        ? apiPrefix.substring(0, apiPrefix.length - 1)
        : apiPrefix;
    final r = rel.startsWith('/') ? rel : '/$rel';
    return '$base$r';
  }

  Map<String, String> _passkeyHeaders(ServerSettings cfg) => {
        'Content-Type': 'application/json',
        if (cfg.passkeyOriginRequestHeaderValue != null)
          _kWebAuthnPublicOriginHeader: cfg.passkeyOriginRequestHeaderValue!,
      };

  /// GET `{origin}{path}/api/ui-nav-hints` must return 200 + JSON for the current session.
  /// Fails if the path does not hit the panel or returns HTML (404 login page, etc.).
  static Future<bool> probePanelBasePath({
    required AuthStore auth,
    required ServerSettings cfg,
    required String proposedPath,
  }) async {
    final client = auth.http;
    if (client == null) return false;
    final origin = cfg.originNormalized;
    final p = ServerOrigin.normalizeBasePath(proposedPath);
    final prefix = p.isEmpty ? origin : '$origin$p';
    try {
      final res = await client.dio.get<dynamic>(
        '$prefix/api/ui-nav-hints',
        options: Options(
          followRedirects: false,
          validateStatus: (c) => c != null && c < 500,
        ),
      );
      if (res.statusCode != 200) return false;
      return res.data is Map;
    } catch (_) {
      return false;
    }
  }

  Future<List<WgClientEnvelope>> fetchClients() async {
    final res = await _dio.get<String>(
      _u('/api/clients'),
      options: Options(
        followRedirects: false,
        validateStatus: (c) => c == 200,
        responseType: ResponseType.plain,
      ),
    );
    final list = jsonDecode(res.data!) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(WgClientEnvelope.fromFlexible)
        .toList();
  }

  Future<WgClientEnvelope> fetchClientDetail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(
      _u('/api/client/$id'),
      options: Options(
        followRedirects: false,
        validateStatus: (c) => c == 200,
      ),
    );
    return WgClientEnvelope.fromFlexible(res.data!);
  }

  Future<DashboardStatsVm> dashboardStats() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _u('/api/dashboard-stats'),
      options: Options(followRedirects: false, validateStatus: (c) => c == 200),
    );
    return DashboardStatsVm.fromJson(res.data!);
  }

  Future<Map<String, PeerTrafficRow>> peerStatsMap() async {
    final res = await _dio.get<dynamic>(
      _u('/api/wg-peer-stats'),
      options: Options(followRedirects: false, validateStatus: (c) => c == 200),
    );
    return PeerTrafficRow.mapFromJson(res.data);
  }

  Future<TrafficSeriesResponseVm> trafficSeries({String range = '24h'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      _u('/api/wg-traffic-series'),
      queryParameters: {'range': range},
      options: Options(followRedirects: false, validateStatus: (c) => c == 200),
    );
    return TrafficSeriesResponseVm.fromJson(res.data!);
  }

  Future<Map<String, dynamic>> tunnelStatus() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _u('/api/wireguard/tunnel-status'),
      options: Options(followRedirects: false, validateStatus: (c) => c == 200),
    );
    return res.data!;
  }

  /// POST `/api/push/register` — binds the FCM token to the current session user.
  Future<bool> registerPushToken({
    required String token,
    String platform = 'android',
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _u('/api/push/register'),
        data: jsonEncode({'token': token, 'platform': platform}),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          followRedirects: false,
          validateStatus: (c) => c == 200,
        ),
      );
      return res.data?['status'] == true;
    } catch (_) {
      return false;
    }
  }

  /// POST `/api/push/unregister` — removes the token (e.g. on sign-out).
  Future<bool> unregisterPushToken(String token) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _u('/api/push/unregister'),
        data: jsonEncode({'token': token}),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          followRedirects: false,
          validateStatus: (c) => c == 200,
        ),
      );
      return res.data?['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> uiNavHints() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _u('/api/ui-nav-hints'),
      options:
          Options(followRedirects: false, validateStatus: (c) => c != null && c < 500),
    );
    if (res.statusCode != 200) return null;
    return res.data;
  }

  Future<SystemLogsSnapshot?> systemLogs() async {
    final res = await _dio.get<dynamic>(
      _u('/api/system-logs'),
      options: Options(
        followRedirects: false,
        validateStatus: (c) => c != null && (c == 200 || c == 403),
      ),
    );
    if (res.statusCode != 200) return null;
    final d = res.data;
    if (d is Map<String, dynamic>) return SystemLogsSnapshot.fromJson(d);
    return null;
  }

  /// Same DB flag as web global settings “realtime stats” / Logs nav (`realtime_stats_enabled`).
  /// Requires admin session; returns false on 403/401/error.
  Future<bool> setRealtimeStatsEnabled(bool enabled) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _u('/api/global-settings/realtime-stats'),
        data: jsonEncode({'realtime_stats_enabled': enabled}),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          followRedirects: false,
          validateStatus: (c) => c != null &&
              (c == 200 || c == 403 || c == 401 || c == 400 || c == 404),
        ),
      );
      if (res.statusCode == 200) return res.data?['status'] == true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> suggestIps({String? subnetRange}) async {
    final res = await _dio.get<dynamic>(
      _u('/api/suggest-client-ips'),
      queryParameters: {
        if (subnetRange != null && subnetRange.isNotEmpty) 'sr': subnetRange,
      },
      options: Options(followRedirects: false, validateStatus: (c) => c == 200),
    );
    final d = res.data;
    if (d is List) return d.map((e) => '$e').toList();
    return [];
  }

  /// `GET /test-hash` — `status: true` when DB hashes differ from last applied (same as web).
  Future<bool> wgConfNeedsApply() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _u('/test-hash'),
      options: Options(
        followRedirects: false,
        validateStatus: (c) => c == 200,
      ),
    );
    return res.data?['status'] == true;
  }

  /// POST `/api/apply-wg-config` — same as the web UI **Apply** action.
  Future<bool> applyWireGuardConfig() async {
    // ContentTypeJson middleware requires this header even with an empty JSON body.
    final res = await _dio.post<Map<String, dynamic>>(
      _u('/api/apply-wg-config'),
      data: '{}',
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (c) => c == 200,
      ),
    );
    return res.data?['status'] == true;
  }

  /// Persists to DB only; pushing to the tunnel is the **Apply config** button (app or web).
  Future<bool> setClientEnabled(String id, bool enabled) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _u('/client/set-status'),
      data: jsonEncode({'id': id, 'status': enabled}),
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (c) => c == 200,
      ),
    );
    return res.data?['status'] == true;
  }

  Future<WgClient?> createClient(WgClient draft) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _u('/new-client'),
      data: jsonEncode(_clientToPost(draft)),
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (c) => c == 200,
      ),
    );
    return WgClient.fromJson(res.data!);
  }

  Future<bool> removeClient(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _u('/remove-client'),
      data: jsonEncode({'id': id}),
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (c) => c == 200,
      ),
    );
    return res.data?['status'] == true;
  }

  Future<ProfileUserVm> fetchUser(String username) async {
    final enc = Uri.encodeComponent(username);
    final res = await _dio.get<Map<String, dynamic>>(
      _u('/api/user/$enc'),
      options: Options(
        followRedirects: false,
        validateStatus: (c) => c == 200,
      ),
    );
    return ProfileUserVm.fromJson(res.data!);
  }

  /// Resolves the logged-in username (same response also lists passkeys).
  Future<ProfilePasskeysSnapshot> fetchProfilePasskeysSnapshot() async {
    final res = await _dio.get<Map<String, dynamic>>(
      _u('/api/profile/passkeys'),
      options: Options(
        followRedirects: false,
        validateStatus: (c) => c == 200,
      ),
    );
    final d = res.data!;
    final un = d['username']?.toString().trim() ?? '';
    final list = d['passkeys'];
    final keys = list is List
        ? list
            .whereType<Map<String, dynamic>>()
            .map(PasskeyItemVm.fromJson)
            .toList()
        : <PasskeyItemVm>[];
    final pe = d['passkeys_enabled'];
    final passkeysEnabled = pe is bool ? pe : true;
    return ProfilePasskeysSnapshot(
      username: un,
      passkeys: keys,
      passkeysEnabled: passkeysEnabled,
    );
  }

  /// `POST /api/passkeys/register/:username/begin` — WebAuthn creation options (session cookie).
  Future<Map<String, dynamic>> passkeyRegisterBegin({
    required String username,
    required ServerSettings cfg,
  }) async {
    final enc = Uri.encodeComponent(username);
    final res = await _dio.post<dynamic>(
      _u('/api/passkeys/register/$enc/begin'),
      data: '{}',
      options: Options(
        headers: _passkeyHeaders(cfg),
        followRedirects: false,
        validateStatus: (c) => c != null && c < 600,
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 40),
      ),
    );
    final code = res.statusCode ?? 0;
    final raw = res.data;
    if (code != 200 || raw is! Map) {
      final msg =
          raw is Map ? '${raw['message'] ?? 'HTTP $code'}' : 'HTTP $code';
      throw StateError(msg);
    }
    return Map<String, dynamic>.from(raw);
  }

  /// `POST /api/passkeys/register/:username/finish` — attestation + optional `credential_name`.
  Future<PasskeyMutationResult> passkeyRegisterFinish({
    required String username,
    required ServerSettings cfg,
    required Map<String, dynamic> webauthnBody,
  }) async {
    final enc = Uri.encodeComponent(username);
    final res = await _dio.post<Map<String, dynamic>>(
      _u('/api/passkeys/register/$enc/finish'),
      data: jsonEncode(webauthnBody),
      options: Options(
        headers: _passkeyHeaders(cfg),
        followRedirects: false,
        validateStatus: (c) => c != null && c < 600,
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 70),
      ),
    );
    final code = res.statusCode ?? 0;
    final d = res.data ?? {};
    if (code != 200) {
      return PasskeyMutationResult(
        ok: false,
        message: d['message']?.toString() ?? 'Error HTTP $code',
      );
    }
    return PasskeyMutationResult(
      ok: d['status'] == true,
      message: d['message']?.toString(),
    );
  }

  Future<UpdateUserResult> updateUser({
    required String previousUsername,
    required String username,
    required String displayName,
    required String email,
    required String password,
    required bool admin,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _u('/update-user'),
      data: jsonEncode({
        'previous_username': previousUsername,
        'username': username,
        'display_name': displayName,
        'email': email,
        'password': password,
        'admin': admin,
      }),
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (c) => c != null && c < 500,
      ),
    );
    final code = res.statusCode ?? 0;
    final d = res.data ?? {};
    if (code != 200) {
      return UpdateUserResult(
        ok: false,
        message: d['message']?.toString() ?? 'Error HTTP $code',
      );
    }
    final reauth = d['reauthenticate'] == true;
    return UpdateUserResult(
      ok: d['status'] == true,
      message: d['message']?.toString(),
      reauthenticate: reauth,
    );
  }

  Future<PasskeyMutationResult> passkeyRemove({
    required String username,
    required String credentialId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _u('/api/passkeys/remove'),
      data: jsonEncode({
        'username': username,
        'credential_id': credentialId,
      }),
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (c) => c != null && c < 500,
      ),
    );
    final code = res.statusCode ?? 0;
    final d = res.data ?? {};
    if (code != 200) {
      return PasskeyMutationResult(
        ok: false,
        message: d['message']?.toString() ?? 'Error HTTP $code',
      );
    }
    return PasskeyMutationResult(
      ok: d['status'] == true,
      message: d['message']?.toString(),
      reauthenticate: d['reauthenticate'] == true,
    );
  }

  Future<PasskeyMutationResult> passkeyRename({
    required String username,
    required String credentialId,
    required String name,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _u('/api/passkeys/rename'),
      data: jsonEncode({
        'username': username,
        'credential_id': credentialId,
        'name': name,
      }),
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (c) => c != null && c < 500,
      ),
    );
    final code = res.statusCode ?? 0;
    final d = res.data ?? {};
    if (code != 200) {
      return PasskeyMutationResult(
        ok: false,
        message: d['message']?.toString() ?? 'Error HTTP $code',
      );
    }
    return PasskeyMutationResult(
      ok: d['status'] == true,
      message: d['message']?.toString(),
    );
  }

  /// `GET /download-all-configs` — administrators only. Returns `null` on 403/404.
  Future<Uint8List?> fetchDownloadAllConfigsZip() async {
    final res = await _dio.get<dynamic>(
      _u('/download-all-configs'),
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (c) =>
            c != null && (c == 200 || c == 403 || c == 404),
      ),
    );
    final code = res.statusCode ?? 0;
    if (code == 403 || code == 404) return null;
    if (code != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'Descarga masiva HTTP $code',
      );
    }
    final data = res.data;
    if (data is! List<int>) return null;
    return Uint8List.fromList(data);
  }

  /// Un `.conf` por peer (`GET /download?clientid=`).
  Future<Uint8List> fetchClientConfBytes(String clientId) async {
    final res = await _dio.get<dynamic>(
      _u('/download?clientid=${Uri.encodeQueryComponent(clientId)}'),
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (c) => c == 200,
      ),
    );
    final data = res.data;
    if (data is! List<int>) {
      throw StateError('Invalid download response');
    }
    return Uint8List.fromList(data);
  }

  /// Builds a ZIP by downloading each config (non-admin users).
  Future<Uint8List> buildPeersConfigZip(List<WgClientEnvelope> peers) async {
    final archive = Archive();
    final used = <String, int>{};
    final re = RegExp(r'[^a-zA-Z0-9._-]+');
    for (final e in peers) {
      final bytes = await fetchClientConfBytes(e.client.id);
      var base = e.client.name.trim();
      if (base.isEmpty) base = 'peer-${e.client.id}';
      base = base.replaceAll(re, '_').trim();
      base = base.replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');
      if (base.isEmpty) base = 'peer-${e.client.id}';
      final n = used[base] ?? 0;
      used[base] = n + 1;
      final fname = n == 0 ? base : '${base}_${n + 1}';
      archive.addFile(ArchiveFile('$fname.conf', bytes.length, bytes));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  /// Prefers the server-built ZIP; if forbidden, builds the ZIP on the client.
  Future<Uint8List> downloadAllPeersAsZip(List<WgClientEnvelope> peers) async {
    if (peers.isEmpty) {
      throw StateError('No peers');
    }
    final serverZip = await fetchDownloadAllConfigsZip();
    if (serverZip != null && serverZip.isNotEmpty) {
      return serverZip;
    }
    return buildPeersConfigZip(peers);
  }

  Map<String, dynamic> _clientToPost(WgClient c) => {
        'name': c.name,
        'allocated_ips': c.allocatedIps,
        'allowed_ips': c.allowedIps,
        'extra_allowed_ips': c.extraAllowedIps,
        'email': c.email,
        'endpoint': c.endpoint,
        'use_server_dns': c.useServerDns,
        'enabled': c.enabled,
        'additional_notes': c.additionalNotes,
        if (c.publicKey.isNotEmpty) 'public_key': c.publicKey,
        if (c.privateKey.isNotEmpty) 'private_key': c.privateKey,
        if (c.presharedKey.isNotEmpty) 'preshared_key': c.presharedKey,
      };
}
