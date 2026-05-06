import 'package:cookie_jar/cookie_jar.dart';

import '../crypto/crypto_store.dart';

class SecureCookieStorage implements Storage {
  final FileStorage _delegate;

  SecureCookieStorage(String dir) : _delegate = FileStorage(dir);

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) {
    return _delegate.init(persistSession, ignoreExpires);
  }

  @override
  Future<String?> read(String key) async {
    final raw = await _delegate.read(key);
    if (raw == null) return null;
    try {
      return await CryptoStore.decryptString(raw);
    } catch (_) {
      // Fallback: if decryption fails (e.g. old plain text cookie), invalidate it.
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    final encrypted = await CryptoStore.encryptString(value);
    return _delegate.write(key, encrypted);
  }

  @override
  Future<void> delete(String key) {
    return _delegate.delete(key);
  }

  @override
  Future<void> deleteAll(List<String> keys) {
    return _delegate.deleteAll(keys);
  }
}
