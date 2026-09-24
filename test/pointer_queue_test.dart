import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/model/pointer_queue.dart';

void main() {
  test('slow network coalesces moves and preserves release', () async {
    final blocked = Completer<void>();
    final sent = <(int, int, int, int)>[];
    final queue = PointerQueue((x, y, buttons, generation) async {
      sent.add((x, y, buttons, generation));
      if (sent.length == 1) await blocked.future;
    }, (error) => fail('$error'));
    for (var x = 0; x < 1000; x++) {
      queue.send(x, 10, 1, 1);
    }
    queue.send(999, 10, 0, 1);
    expect(sent.length, 1);
    blocked.complete();
    await Future<void>.delayed(Duration.zero);
    expect(sent, [(0, 10, 1, 1), (999, 10, 1, 1), (999, 10, 0, 1)]);
  });
  test('new frame generation drops queued old motion', () async {
    final blocked = Completer<void>();
    final sent = <int>[];
    final queue = PointerQueue((x, y, buttons, generation) async {
      sent.add(generation);
      if (sent.length == 1) await blocked.future;
    }, (error) => fail('$error'));
    queue.send(1, 1, 1, 1);
    queue.send(2, 2, 1, 1);
    queue.send(3, 3, 0, 1);
    queue.send(4, 4, 1, 2);
    queue.send(4, 4, 0, 2);
    blocked.complete();
    await Future<void>.delayed(Duration.zero);
    expect(sent, [1, 2, 2]);
  });
}
