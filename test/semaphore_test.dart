import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/semaphore.dart';

void main() {
  test('plafonne les opérations en vol', () async {
    final gate = Semaphore(2);
    var inFlight = 0;
    var peak = 0;
    Future<void> task() => gate.run(() async {
          peak = (++inFlight) > peak ? inFlight : peak;
          await Future<void>.delayed(Duration.zero);
          inFlight--;
        });
    await Future.wait([for (var i = 0; i < 6; i++) task()]);
    expect(peak, 2);
  });

  test('une opération urgente passe devant celles qui attendent', () async {
    final gate = Semaphore(1);
    final order = <String>[];
    final blocker = Completer<void>();
    final first = gate.run(() => blocker.future);
    final queued = [
      gate.run(() async => order.add('autre 1')),
      gate.run(() async => order.add('autre 2')),
      gate.run(() async => order.add('site affiché'), urgent: true),
    ];
    blocker.complete();
    await Future.wait([first, ...queued]);
    expect(order, ['site affiché', 'autre 1', 'autre 2']);
  });
}
