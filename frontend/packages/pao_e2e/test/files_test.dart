import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_e2e/secrets_file.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('pao_e2e'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('keeps secrets in an email=secret file, the newest winning', () async {
    final secrets = FileSecrets('${dir.path}/.admins.env');
    expect(await secrets.read('a@pao.bd'), isNull);
    await secrets.write('a@pao.bd', 'ONE');
    await secrets.write('b@pao.bd', 'TWO');
    await secrets.write('a@pao.bd', 'THREE');
    expect(await secrets.read('a@pao.bd'), 'THREE');
    expect(await secrets.read('c@pao.bd'), isNull);
  });

  test('reads KEY=value files and builds the stack admins', () {
    final env = File('${dir.path}/.stack.env')
      ..writeAsStringSync('PAO_E2E_API=http://x:1\nnot a pair\nP=a=b\n');
    expect(readEnvFile(env.path), {'PAO_E2E_API': 'http://x:1', 'P': 'a=b'});
    expect(stackAdmins(StackClient('http://x')).password, isEmpty);
  });

  test('device stand-ins: Banani and a decodable photo', () async {
    // Built through the tear-off so the constructor itself runs.
    const make = FixedLocation.new;
    final point = await make().current();
    expect([point!.lat, point.lng], [23.7937, 90.4066]);
    final photos = StubPhotos();
    expect(await photos.capture(selfie: true), stubJpeg);
    expect(await photos.pick(), stubJpeg);
    expect(stubJpeg.take(2), [0xff, 0xd8]);
  });
}
