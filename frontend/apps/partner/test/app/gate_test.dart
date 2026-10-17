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

  test('crossing the gate reloads the screens of the account', () async {
    final h = await Harness.create();
    var loads = 0;
    h.http
      ..onGet('/v1/provider/verification', (s) => s.reply(200, verification()))
      ..onGet('/v1/me/permissions', (s) {
        loads++;
        s.reply(200, {
          'roles': ['provider'],
          'permissions': <String>[],
          'screens': allScreens,
        });
      });
    final gate = h.services.gate;
    await gate.load();
    await gate.load();
    expect([loads, h.services.permissions.canSee('M15')], [1, true]);
    h.http.onGet(
      '/v1/provider/verification',
      (s) => s.reply(200, verification(cleared: false)),
    );
    h.http.onGet('/v1/me/permissions', (s) => s.reply(500, null));
    await gate.load();
    expect(gate.cleared, isFalse);
  });
}
