class AttendanceSyncControl {
  static bool _running = false;
  static bool tryAcquire() {
    if (_running) {
      return false;
    }
    _running = true;
    return true;
  }

  static void release() {
    _running = false;
  }

  static bool conflicts(String? base, String server, String desired) {
    return server != (base ?? server) && server != desired;
  }

  static Future<void> send(List<Future<void> Function()> operations) async {
    var next = 0;
    Future<void> worker() async {
      while (next < operations.length) {
        final operation = operations[next++];
        await operation();
      }
    }

    await Future.wait(
      List.generate(operations.length < 4 ? operations.length : 4, (_) {
        return worker();
      }),
    );
  }
}
