import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  test('defaults point at the local API in the dev flavour', () {
    final env = Env.fromDefines();
    expect(env.apiBaseUrl, 'http://localhost:8080');
    expect(env.flavour, 'dev');
  });
}
