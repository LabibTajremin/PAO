import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  test(
    'gate clears with the status, keeps it on failure, clears on demand',
    () async {
      final h = await Harness.create();
      final gate = h.services.gate;
      expect(gate.cleared, isFalse);
      h.http.onGet(
        '/v1/provider/verification',
        (s) => s.reply(200, verification()),
      );
      await gate.load();
      expect([gate.cleared, gate.status!.level], [true, 1]);
      h.http.onGet('/v1/provider/verification', (s) => s.reply(500, null));
      await gate.load();
      expect(gate.cleared, isTrue);
      gate.clear();
      expect(gate.status, isNull);
    },
  );
}
