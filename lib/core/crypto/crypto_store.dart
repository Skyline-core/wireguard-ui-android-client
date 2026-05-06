import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyAlias = 'wgui_master_key';

  static Key? _key;

  static Future<Key> _getKey() async {
    if (_key != null) return _key!;
    String? base64Key = await _storage.read(key: _keyAlias);
    if (base64Key == null) {
      final secureRandom = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => secureRandom.nextInt(256));
      base64Key = base64UrlEncode(keyBytes);
      await _storage.write(key: _keyAlias, value: base64Key);
    }
    _key = Key(base64Url.decode(base64Key));
    return _key!;
  }

  static Future<String> encryptString(String raw) async {
    if (raw.isEmpty) return '';
    final key = await _getKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(raw, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static Future<String> decryptString(String encryptedText) async {
    if (encryptedText.isEmpty) return '';
    final parts = encryptedText.split(':');
    if (parts.length != 2) throw Exception('Invalid encrypted format');
    final key = await _getKey();
    final iv = IV.fromBase64(parts[0]);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt(Encrypted.fromBase64(parts[1]), iv: iv);
  }
}
