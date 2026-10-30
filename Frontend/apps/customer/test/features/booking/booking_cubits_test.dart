import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';
import 'package:pao_customer/features/booking/domain/schedule.dart';
import 'package:pao_customer/features/booking/presentation/setup_cubit.dart';
import 'package:pao_customer/features/booking/presentation/track_cubit.dart';
import 'package:pao_customer/shared/booking_draft.dart';

import 'booking_fixtures.dart';

final _now = DateTime.utc(2026, 10, 9, 4);

Map<String, Object?> _requested() => booking(status: 'requested');

class _Repo implements BookingRepository {
  Map<String, Object?> json = _requested();
  String model = 'on_demand';
  List<Map<String, Object?>> saved = [
    address('a2', label: 'office'),
    address('a1', isDefault: true),
  ];
  AppFailure? fail;
  final keys = <String>[];

  @override
  Future<BookingOptions> options(String serviceId, String providerId) async {
    if (fail != null) throw fail!;
    return BookingOptions(
      service: Service.fromJson(service(model: model)),
      provider: ProviderPublicProfile.fromJson(providerProfile),
      addresses: await addresses(),
    );
  }

  @override
  Future<List<Address>> addresses() async => [
    for (final a in saved) Address.fromJson(a),
  ];

  @override
  Future<Booking> create(BookingCreate request, {required String key}) async {
    keys.add(key);
    if (fail != null) throw fail!;
    return Booking.fromJson(json);
  }

  @override
  Future<Booking> booking(String id) async {
    if (fail != null) throw fail!;
    return Booking.fromJson(json);
  }
}

void main() {
  test('Dhaka wall time converts both ways and bounds the schedule', () {
    final at = fromDhaka(DateTime(2026, 10, 9), 15, 30);
    expect(at, DateTime.utc(2026, 10, 9, 9, 30));
    expect(toDhaka(at), DateTime(2026, 10, 9, 15, 30));
    expect(schedulable(_now.add(const Duration(minutes: 59)), _now), isFalse);
    expect(schedulable(_now.add(const Duration(hours: 1)), _now), isTrue);
    expect(schedulable(_now.add(const Duration(days: 31)), _now), isFalse);
    expect(newIdempotencyKey(Random(1)), hasLength(32));
    expect(newIdempotencyKey(), isNot(newIdempotencyKey()));
  });

  group('setup', () {
    late _Repo repo;
    var n = 0;
    SetupCubit cubit(BookingDraft draft) =>
        SetupCubit(repo, draft, now: () => _now, newKey: () => 'key-${n++}');
    const draft = BookingDraft(
      serviceId: 's1',
      items: {'x1': 2, 'x3': 1},
      providerId: 'p1',
    );

    setUp(() {
      repo = _Repo();
      n = 0;
    });

    test('prices published items and picks the default address', () async {
      final c = cubit(draft);
      await c.load();
      expect(c.state.addressId, 'a1');
      expect(c.state.timing, Timing.asap);
      expect([for (final l in c.lines) '${l.id}:${l.total}'], ['x1:100000']);
      repo.saved = [address('a3')];
      await c.reloadAddresses();
      expect(c.state.addressId, 'a3');
      repo.saved = [address('a3'), address('a4')];
      c.address('a4');
      await c.reloadAddresses();
      expect(c.state.addressId, 'a4');
    });

    test('a duration hire is scheduled with the draft start', () async {
      repo.model = 'duration_hire';
      final c = cubit(
        const BookingDraft(
          serviceId: 's1',
          items: {'x1': 1},
          providerId: 'p1',
          scheduledAt: '2026-10-09T03:00Z',
        ),
      );
      await c.load();
      expect(c.state.timing, Timing.scheduled);
      await c.confirm('');
      expect(c.state.invalidTime, isTrue);
      expect(repo.keys, isEmpty);
      c.schedule(_now.add(const Duration(minutes: 10)));
      expect(c.state.invalidTime, isTrue);
      c.schedule(_now.add(const Duration(hours: 3)));
      expect(c.state.invalidTime, isFalse);
      await c.confirm('');
      expect(c.state.booking!.id, 'b1');
    });

    test('a retry reuses the key; a changed request gets a new one', () async {
      final c = cubit(draft);
      await c.load();
      repo.fail = const NetworkFailure();
      await c.confirm(' Gate 4 ');
      await c.confirm('Gate 4');
      expect(c.state.failure!.code, 'NETWORK');
      c.timing(Timing.scheduled);
      await c.confirm('Gate 4');
      expect(c.state.invalidTime, isTrue);
      c
        ..timing(Timing.asap)
        ..address('a2');
      await c.confirm('Gate 4');
      repo.fail = null;
      await c.confirm('Gate 4');
      expect(repo.keys, ['key-0', 'key-0', 'key-1', 'key-1']);
      expect(c.state.booking, isNotNull);
    });

    test('load and address failures are reported', () async {
      final c = cubit(draft);
      repo.fail = const NetworkFailure();
      await c.load();
      expect(c.state.view, isA<ViewFailure<BookingOptions>>());
      repo.fail = null;
      await c.load();
      repo.saved = [];
      final broken = _Broken(repo);
      final c2 = SetupCubit(broken, draft, now: () => _now);
      await c2.load();
      await c2.reloadAddresses();
      expect(c2.state.failure!.code, 'TIMEOUT');
    });
  });

  group('track', () {
    late _Repo repo;
    late StreamController<void> ticks;
    late TrackCubit cubit;

    setUp(() {
      repo = _Repo()
        ..json = booking(status: 'requested', deadline: '2026-10-09T04:00:03Z');
      ticks = StreamController<void>.broadcast();
      cubit = TrackCubit(repo, 'b1', now: () => _now, ticks: ticks.stream);
    });

    tearDown(() async {
      await cubit.close();
      await ticks.close();
    });

    Future<void> tick([int count = 1]) async {
      for (var i = 0; i < count; i++) {
        ticks.add(null);
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('counts down and polls every fifth tick', () async {
      await cubit.load();
      expect(cubit.state.left, const Duration(seconds: 3));
      await tick(3);
      expect(cubit.state.expired, isTrue);
      repo.fail = const NetworkFailure();
      await tick(2);
      expect([cubit.state.stale, cubit.state.expired], [true, true]);
      repo
        ..fail = null
        ..json = booking();
      await tick(5);
      expect(
        [cubit.state.booking!.status, cubit.state.left],
        [BookingStatus.accepted, null],
      );
      repo.json = booking(status: 'cancelled');
      await tick(5);
      expect(ticks.hasListener, isFalse);
    });

    test('a past deadline is already expired; a failed load retries', () async {
      repo
        ..json = booking(status: 'requested', deadline: '2026-10-09T03:59:00Z')
        ..fail = const NetworkFailure();
      await cubit.load();
      expect(cubit.state.view, isA<ViewFailure<Booking>>());
      repo.fail = null;
      await tick(5);
      expect(cubit.state.expired, isTrue);
    });

    test('a finished booking is not followed', () async {
      repo.json = booking(status: 'completed');
      await cubit.load();
      expect(ticks.hasListener, isFalse);
      await cubit.close();
      await cubit.refresh();
    });
  });
}

class _Broken extends _Repo {
  _Broken(_Repo base) {
    saved = [address('a1')];
    json = base.json;
  }

  var _calls = 0;

  @override
  Future<List<Address>> addresses() async {
    if (_calls++ > 0) throw const NetworkFailure(timedOut: true);
    return await super.addresses();
  }
}
