import 'package:flutter/foundation.dart';

/// MainShell listens and refreshes tabs after the API base path changes.
class AppReloadSignal extends ChangeNotifier {
  void notifyReload() => notifyListeners();
}
