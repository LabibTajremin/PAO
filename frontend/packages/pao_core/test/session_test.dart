import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> roundTrip(SessionStore store) async {
    expect(await store.read(), isNull);
    await store.write(const Session(accessToken: 'a', refreshToken: 'r'));
    final got = await store.read();
    expect([got!.accessToken, got.refreshToken], ['a', 'r']);
    await store.delete();
    expect(await store.read(), isNull);
  }

  test('memory store', () => roundTrip(MemorySessionStore()));

  test('secure store', () {
    FlutterSecureStorage.setMockInitialValues({});
    return roundTrip(SecureSessionStore());
  });

  test('manager restores, signs in and signs out', () async {
    final store = MemorySessionStore();
    await store.write(const Session(accessToken: 'saved'));
    final m = SessionManager(store);
    var notified = 0;
    m.addListener(() => notified++);
    await m.restore();
    expect(m.session!.accessToken, 'saved');
    await m.signOut(expired: true);
    expect([m.signedIn, m.expired], [false, true]);
    await m.signIn(const Session(accessToken: 'new'));
    expect([m.signedIn, m.expired], [true, false]);
    expect(notified, 3);
  });
}
