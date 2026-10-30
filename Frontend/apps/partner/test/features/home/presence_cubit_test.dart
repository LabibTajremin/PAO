import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/home/domain/heartbeat.dart';
import 'package:pao_partner/features/home/domain/home_repository.dart';
import 'package:pao_partner/features/home/domain/online_memory.dart';
import 'package:pao_partner/features/home/presentation/presence_cubit.dart';

import '../../support/harness.dart';

class _Repo implements HomeRepository {
  final calls = <String>[];
  AppFailure? fail;
  AppFailure? beatFail;
  Completer<void>? hold;

  @override
  Future<HomeSummary> summary() => throw UnimplementedError();

  @override
  Future<Duration> goOnline(GeoPoint at) async {
    calls.add('online ${at.lat}');
    await hold?.future;
    if (fail != null) throw fail!;
    return const Duration(seconds: 30);
  }

  @override
  Future<void> goOffline() async {
    calls.add('offline');
    if (fail != null) throw fail!;
  }

  @override
  Future<void> heartbeat(GeoPoint at) async {
    calls.add('beat');
    if (beatFail != null) throw beatFail!;
  }
}

class _Beat implements Heartbeat {
  Duration? every;
  Future<void> Function()? beat;

  @override
  void start(Duration every, Future<void> Function() beat) {
    this.every = every;
    this.beat = beat;
  }

  @override
  void stop() => beat = null;
}

class _Memory implements OnlineMemory {
  @override
  bool online = false;

  @override
  Future<void> remember({required bool online}) async => this.online = online;
}

void main() {
  late _Repo repo;
  late FakeLocation location;
  late _Beat beat;
  late _Memory memory;
  late PresenceCubit cubit;

  setUp(() {
    repo = _Repo();
    location = FakeLocation();
    beat = _Beat();
    memory = _Memory();
    cubit = PresenceCubit(repo, location, beat, memory);
  });

  tearDown(() => cubit.close());

  test('resumes only when the provider was online', () async {
    await cubit.resume();
    expect(repo.calls, isEmpty);
    memory.online = true;
    await cubit.resume();
    expect(cubit.state.online, isTrue);
  });

  test('going online starts the heartbeat; offline stops it', () async {
    await cubit.toggle();
    expect(
      [cubit.state.online, memory.online, beat.every],
      [true, true, const Duration(seconds: 30)],
    );
    await beat.beat!();
    expect(repo.calls, ['online 23.794', 'beat']);
    await cubit.toggle();
    expect(
      [cubit.state.online, memory.online, beat.beat],
      [false, false, null],
    );
  });

  test('location off refuses to go online', () async {
    location.point = null;
    await cubit.goOnline();
    expect([cubit.state.locationOff, cubit.state.online], [true, false]);
    expect(repo.calls, isEmpty);
  });

  test('a refused switch reports why', () async {
    repo.fail = const ApiFailure('NOT_VERIFIED', status: 409);
    await cubit.goOnline();
    expect([cubit.state.failure!.code, beat.beat], ['NOT_VERIFIED', null]);
    await cubit.goOffline();
    expect(
      [cubit.state.online, cubit.state.failure!.code],
      [false, 'NOT_VERIFIED'],
    );
  });

  test(
    'heartbeats skip without a fix and stop when the server says offline',
    () async {
      await cubit.goOnline();
      location.point = null;
      await beat.beat!();
      location.point = const GeoPoint(23.8, 90.4);
      repo.beatFail = const NetworkFailure();
      await beat.beat!();
      expect(cubit.state.online, isTrue);
      repo.beatFail = const ApiFailure('CONFLICT', status: 409);
      await beat.beat!();
      expect(
        [cubit.state.online, memory.online, beat.beat],
        [false, false, null],
      );
      expect(repo.calls.where((c) => c == 'beat'), hasLength(2));
    },
  );

  test('closing mid-switch leaves no heartbeat behind', () async {
    repo.hold = Completer<void>();
    final going = cubit.goOnline();
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    repo.hold!.complete();
    await going;
    expect(beat.beat, isNull);
  });

  testWidgets('the timer heartbeat beats until stopped', (tester) async {
    final heartbeat = TimerHeartbeat();
    var beats = 0;
    Future<void> count() async => beats++;
    heartbeat.start(const Duration(seconds: 30), count);
    await tester.pump(const Duration(seconds: 30));
    heartbeat.start(const Duration(seconds: 10), count);
    await tester.pump(const Duration(seconds: 25));
    heartbeat.stop();
    await tester.pump(const Duration(seconds: 60));
    expect(beats, 3);
  });
}
