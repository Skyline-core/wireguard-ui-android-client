import 'dart:convert';
import 'dart:typed_data';

import 'package:passkeys/types.dart';

/// Respuesta de `POST .../api/passkeys/register/:user/begin` (objeto [CredentialCreation] de go-webauthn).
RegisterRequestType parsePasskeyRegisterBeginOptions(Map<String, dynamic> beginJson) {
  final rawPk = beginJson['publicKey'];
  final Map<String, dynamic> pk = rawPk is Map<String, dynamic>
      ? Map<String, dynamic>.from(rawPk)
      : Map<String, dynamic>.from(beginJson);

  pk['challenge'] = _challengeToBase64Url(pk['challenge']);

  _normalizeRegisterRp(pk);
  _normalizeRegisterUser(pk);
  _normalizeAuthenticatorSelectionForRegister(pk);
  _normalizePubKeyCredParamsForRegister(pk);

  final user = pk['user'];
  if (user is Map<String, dynamic>) {
    final u = Map<String, dynamic>.from(user);
    u['id'] = _userIdToBase64UrlString(u['id']);
    pk['user'] = u;
  }

  final exclude = pk['excludeCredentials'];
  if (exclude is List<dynamic>) {
    pk['excludeCredentials'] = exclude.map((dynamic e) {
      if (e is! Map<String, dynamic>) return e;
      final m = Map<String, dynamic>.from(e);
      m['id'] = _credentialIdToBase64Url(m['id']);
      m['type'] = (m['type'] ?? 'public-key').toString();
      final tRaw = m['transports'];
      if (tRaw is List && tRaw.isNotEmpty) {
        m['transports'] = tRaw.map((Object? x) => '$x').toList();
      } else {
        m['transports'] = <String>[];
      }
      return m;
    }).toList();
  }

  return RegisterRequestType.fromJson(pk);
}

/// go-webauthn omite claves con `omitempty`; [RegisterRequestType.fromJson] hace `as String` estricto.
void _normalizeRegisterRp(Map<String, dynamic> pk) {
  final rp = pk['rp'];
  if (rp is! Map) return;
  final r = Map<String, dynamic>.from(rp);
  r['name'] = r['name']?.toString() ?? '';
  r['id'] = r['id']?.toString() ?? '';
  pk['rp'] = r;
}

void _normalizeRegisterUser(Map<String, dynamic> pk) {
  final u = pk['user'];
  if (u is! Map) return;
  final user = Map<String, dynamic>.from(u);
  user['displayName'] = user['displayName']?.toString() ?? '';
  user['name'] = user['name']?.toString() ?? '';
  pk['user'] = user;
}

/// [AuthenticatorSelectionType] exige [requireResidentKey], [residentKey], [userVerification] no nulos.
void _normalizeAuthenticatorSelectionForRegister(Map<String, dynamic> pk) {
  final a = pk['authenticatorSelection'];
  if (a is! Map) return;
  final m = Map<String, dynamic>.from(a);
  final rr = m['requireResidentKey'];
  if (rr is bool) {
    m['requireResidentKey'] = rr;
  } else if (rr == null) {
    m['requireResidentKey'] = false;
  } else {
    m['requireResidentKey'] = rr == true;
  }
  m['residentKey'] = m['residentKey']?.toString() ?? 'preferred';
  m['userVerification'] = m['userVerification']?.toString() ?? 'preferred';
  pk['authenticatorSelection'] = m;
}

void _normalizePubKeyCredParamsForRegister(Map<String, dynamic> pk) {
  final list = pk['pubKeyCredParams'];
  if (list is! List<dynamic>) return;
  pk['pubKeyCredParams'] = list.map((dynamic e) {
    if (e is! Map) return e;
    final p = Map<String, dynamic>.from(e);
    p['type'] = (p['type'] ?? 'public-key').toString();
    final alg = p['alg'];
    if (alg == null) {
      p['alg'] = -7;
    } else if (alg is num) {
      p['alg'] = alg.toInt();
    } else {
      p['alg'] = int.tryParse(alg.toString()) ?? -7;
    }
    return p;
  }).toList();
}

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

/// [UserType.id] debe ser base64url válido; normaliza lo que envía go-webauthn (string o lista de bytes).
String _userIdToBase64UrlString(dynamic value) {
  if (value is String) {
    var s = value.trim().replaceAll('+', '-').replaceAll('/', '_');
    s = _stripBase64Padding(s);
    final pad = (4 - s.length % 4) % 4;
    final padded = s + ('=' * pad);
    final bytes = base64Url.decode(padded);
    return base64Url.encode(bytes);
  }
  if (value is List<dynamic>) {
    final bytes =
        Uint8List.fromList(value.map((e) => (e as num).toInt()).toList());
    return base64Url.encode(bytes);
  }
  throw FormatException('Unsupported user.id: ${value.runtimeType}');
}
