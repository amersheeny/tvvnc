import 'dart:async';

typedef PointerWrite = Future<void> Function(
  int x,
  int y,
  int buttons,
  int generation,
);

/// One in-flight event plus at most one move and a release. Moves are replaceable;
/// press/release edges are not. A stalled network cannot grow an unbounded tail.
class PointerQueue {
  PointerQueue(this.write, this.onError);
  final PointerWrite write;
  final void Function(Object) onError;
  final _pending = <(int, int, int, int)>[];
  bool _running = false;
  void send(int x, int y, int buttons, int generation) {
    _pending.removeWhere((item) => item.$4 != generation);
    final event = (x, y, buttons, generation);
    if (_pending.isNotEmpty &&
        _pending.last.$3 == buttons &&
        _pending.last.$4 == generation) {
      _pending[_pending.length - 1] = event;
    } else {
      if (_pending.length >= 4) {
        // Stop accepting a new drag until outstanding releases are drained.
        if (buttons != 0) return;
        _pending.removeWhere((item) => item.$3 != 0);
      }
      _pending.add(event);
    }
    if (!_running) unawaited(_drain());
  }

  Future<void> _drain() async {
    _running = true;
    try {
      while (_pending.isNotEmpty) {
        final next = _pending.removeAt(0);
        try {
          await write(next.$1, next.$2, next.$3, next.$4);
        } catch (error) {
          onError(error);
        }
      }
    } finally {
      _running = false;
    }
  }
}
