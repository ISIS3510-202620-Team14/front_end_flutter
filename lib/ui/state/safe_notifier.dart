import 'package:flutter/foundation.dart';

class SafeNotifier extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed {
    return _disposed;
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
