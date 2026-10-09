import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  test('loads, answers and clears', () async {
    final dio = Dio();
    DioAdapter(dio: dio).onGet(
      '/v1/me/permissions',
      (server) => server.reply(200, {
        'roles': ['customer'],
        'permissions': ['booking:create'],
        'screens': ['C07'],
      }),
    );
    final p = PermissionService(dio);
    var notified = 0;
    p.addListener(() => notified++);
    await p.load();
    expect(
      [p.can('booking:create'), p.canSee('C07'), p.canSee('A01')],
      [true, true, false],
    );
    expect(p.roles, {'customer'});
    p.clear();
    expect([p.can('booking:create'), p.roles.isEmpty], [false, true]);
    expect(notified, 2);
  });
}
