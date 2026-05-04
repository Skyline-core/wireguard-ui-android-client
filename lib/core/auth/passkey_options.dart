import 'dart:convert';
import 'dart:typed_data';

import 'package:passkeys/types.dart';

/// Normaliza la respuesta de `POST .../api/passkeys/login/begin` para [PasskeyAuthenticator.authenticate].
AuthenticateRequestType parsePasskeyBeginOptions(Map<String, dynamic> beginJson) {
  final status = beginJson['status'] == true;
  if (!status) {
    throw StateError(beginJson['message']?.toString() ?? 'Passkey begin failed');
  }
  final raw = beginJson['options'];
  if (raw == null) {
    throw const FormatException('Missing options in passkey begin response');
  }
  Map<String, dynamic> pk;
  if (raw is Map<String, dynamic>) {
    final inner = raw['publicKey'];
    pk = inner is Map<String, dynamic>
        ? Map<String, dynamic>.from(inner)
        : Map<String, dynamic>.from(raw);
  } else {
    throw FormatException('Invalid options: ${raw.runtimeType}');
  }

  pk['challenge'] = _challengeToBase64Url(pk['challenge']);

  final allow = pk['allowCredentials'];
  if (allow is List<dynamic> && allow.isNotEmpty) {
    pk['allowCredentials'] = allow
        .whereType<Map<String, dynamic>>()
        .map((e) {
          final m = Map<String, dynamic>.from(e);
          m['id'] = _credentialIdToBase64Url(m['id']);
          m['type'] ??= 'public-key';
          // Empty omitted on server (`omitempty`). Do NOT force `[]`: Android Credential
          // Manager often ignores credentials when transports is explicitly empty (W3C: absent ⇒ any transport).
          final tRaw = m['transports'];
          if (tRaw is List && tRaw.isNotEmpty) {
            m['transports'] =
                tRaw.map((Object? x) => '$x').toList(growable: false);
          } else {
            m.remove('transports');
          }
          return m;
        })
        .toList();
  }

  return AuthenticateRequestType.fromJson(
    pk,
    preferImmediatelyAvailableCredentials: false,
  );
}

String _challengeToBase64Url(dynamic value) {
  if (value is String) {
    return _stripBase64Padding(
      value.trim().replaceAll('+', '-').replaceAll('/', '_'),
    );
  }
  if (value is List<dynamic>) {
    final bytes =
        Uint8List.fromList(value.map((e) => (e as num).toInt()).toList());
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
  throw FormatException('Unsupported challenge type: ${value.runtimeType}');
}

String _credentialIdToBase64Url(dynamic value) {
  if (value is String) {
    return _stripBase64Padding(
      value.trim().replaceAll('+', '-').replaceAll('/', '_'),
    );
  }
  if (value is List<dynamic>) {
    final bytes =
        Uint8List.fromList(value.map((e) => (e as num).toInt()).toList());
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
  throw FormatException('Unsupported credential id type: ${value.runtimeType}');
}

String _stripBase64Padding(String s) {
  var t = s;
  while (t.endsWith('=')) {
    t = t.substring(0, t.length - 1);
  }
  return t;
}
