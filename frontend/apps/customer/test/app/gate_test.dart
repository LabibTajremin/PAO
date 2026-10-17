import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';

import '../support/harness.dart';

void main() {
  test('a missing profile closes the gate; other failures keep it', () async {
    final h = await Harness.create();
    final gate = h.services.gate;
    expect([gate.missing, gate.profile], [false, null]);
    h.http.onGet(
      '/v1/customer/profile',
      (s) => s.reply(404, apiError('NOT_FOUND')),
    );
    await gate.load();
    expect(gate.missing, isTrue);
    h.http.onGet('/v1/customer/profile', (s) => s.reply(500, null));
    await gate.load();
    expect(gate.missing, isTrue);
    h.http.onGet('/v1/customer/profile', (s) => s.reply(200, profile()));
    await gate.load();
    expect([gate.missing, gate.profile!.name], [false, 'Nusrat Jahan']);
    gate
      ..clear()
      ..saved(CustomerProfile(id: 'c1', name: 'Rina', language: Language.bn));
    expect([gate.missing, gate.profile!.name], [false, 'Rina']);
  });
}
