import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/connectivity/data/start_code_cache.dart';
import 'package:pao_customer/features/live/data/secure_screen.dart';
import 'package:pao_customer/features/live/domain/live_repository.dart';
import 'package:pao_customer/features/live/presentation/extras_cubit.dart';
import 'package:pao_customer/features/live/presentation/start_code_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../booking/booking_fixtures.dart';

Map<String, Object?> _pending() =>
    booking(status: 'in_progress', pendingExtras: proposal());

class _Repo implements LiveRepository {
  Map<String, Object?> json = _pending();
  AppFailure? fail;
  final decisions = <String>[];

  @override
  Future<Booking> booking(String id) async {
    if (fail != null) throw fail!;
    return Booking.fromJson(json);
  }

  @override
  Future<String> startCode(String id) async {
    if (fail != null) throw fail!;
    return '4821';
  }

  @override
  Future<Booking> decideExtras(
    String id, {
    required String proposalId,
    required bool approve,
  }) async {
    decisions.add('$proposalId $approve');
    if (fail != null) throw fail!;
    return Booking.fromJson(json);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the start code is cached, kept offline and forgotten', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = StartCodeCache(await Prefs.open());
    final repo = _Repo();
    final cubit = StartCodeCubit(repo, cache, 'b1');
    expect(cubit.state.code, isNull);
    await cubit.load();
    expect(cache.read('b1'), '4821');
    repo.fail = const NetworkFailure();
    final offline = StartCodeCubit(repo, cache, 'b1');
    await offline.load();
    expect(
      [offline.state.code, offline.state.failure!.code],
      ['4821', 'NETWORK'],
    );
    await offline.sync(BookingStatus.arrived);
    expect(cache.read('b1'), '4821');
    await offline.sync(BookingStatus.inProgress);
    expect(cache.read('b1'), isNull);
    await cubit.close();
    await offline.close();
    await cubit.load();
    repo.fail = null;
    await offline.load();
  });

  test('extras are decided once; a vanished proposal closes', () async {
    final repo = _Repo();
    final cubit = ExtrasCubit(repo, 'b1');
    await cubit.decide(approve: true);
    expect(repo.decisions, isEmpty);
    await cubit.load();
    expect(cubit.state.pending!.id, 'p1');
    repo.fail = const ApiFailure('EXTRAS_PENDING', status: 409);
    await cubit.decide(approve: false);
    expect(
      [cubit.state.failure!.code, cubit.state.done],
      ['EXTRAS_PENDING', false],
    );
    repo.fail = const ApiFailure('NO_PENDING_EXTRAS', status: 409);
    await cubit.decide(approve: true);
    expect([cubit.state.failure, cubit.state.done], [null, true]);
    expect(repo.decisions, ['p1 false', 'p1 true']);
    await cubit.load();
    expect(cubit.state.view, isA<ViewFailure<Booking>>());
  });

  test('the secure flag goes through the platform channel', () async {
    final calls = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SecureScreen.channel, (call) async {
          calls.add('${call.method} ${call.arguments}');
          return null;
        });
    await const SecureScreen().protect(on: true);
    await const SecureScreen().protect(on: false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SecureScreen.channel, null);
    await const SecureScreen().protect(on: true);
    expect(calls, ['setSecure true', 'setSecure false']);
  });
}
