import 'package:flutter/widgets.dart';

import '../api/wgu_repository.dart';
import 'config/server_settings.dart';
import 'session/auth_store.dart';

/// Pending "Apply config" banner state (same as web `needsWgConfApply`: `GET /test-hash`).
class WgApplyController extends ChangeNotifier {
  /// `true` when DB content differs from stored `hashes.json` (apply needed on server).
  bool? needsApply;
  bool applying = false;
  String? lastError;

  void reset() {
    needsApply = null;
    lastError = null;
    applying = false;
    notifyListeners();
  }

  void _notifyDeferred() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  Future<void> refreshFromServer(AuthStore auth, ServerSettings cfg) async {
    if (!auth.ready || auth.http == null || auth.offlineMode) {
      needsApply = null;
      lastError = null;
      _notifyDeferred();
      return;
    }
    try {
      lastError = null;
      final r = WguRepository.fromContext(auth, cfg);
      needsApply = await r.wgConfNeedsApply();
    } catch (e) {
      lastError = '$e';
    }
    _notifyDeferred();
  }

  Future<bool> applyNow(AuthStore auth, ServerSettings cfg) async {
    if (!auth.ready || auth.http == null || auth.offlineMode || applying) {
      return false;
    }
    applying = true;
    lastError = null;
    notifyListeners();
    try {
      final r = WguRepository.fromContext(auth, cfg);
      final ok = await r.applyWireGuardConfig();
      if (ok) {
        needsApply = await r.wgConfNeedsApply();
      }
      return ok;
    } catch (e) {
      lastError = '$e';
      return false;
    } finally {
      applying = false;
      notifyListeners();
    }
  }
}
