import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/requests/domain/request_repository.dart';
import 'package:pao_partner/features/requests/presentation/request_cubit.dart';

import '../job/job_fixtures.dart';

final _now = DateTime.utc(2026, 10, 9, 4);

class _Repo implements RequestRepository {
  Map<String, Object?> json = booking(
    status: 'requested',
    deadline: '2026-10-09T04:00:03Z',
  );
  AppFailure? fail;
  final calls = <String>[];

  Future<Booking> _act(String call) async {
    calls.add(call);
    if (fail != null) throw fail!;
    return Booking.fromJson(json);
  }

  @override
  Future<Booking> request(String id) => _act('get');

  @override
  Future<Booking> accept(String id) => _act('accept');

  @override
  Future<Booking> reject(
    String id,
    RejectInputReasonEnum reason,
    String? note,
  ) => _act('reject $reason $note');
}

void main() {
  late StreamController<void> ticks;
  late _Repo repo;
  late RequestCubit cubit;

  setUp(() {
    ticks = StreamController<void>.broadcast();
    repo = _Repo();
    cubit = RequestCubit(repo, 'b1', now: () => _now, ticks: ticks.stream);
  });

  tearDown(() async {
    await cubit.close();
    await ticks.close();
  });

  Future<void> tick() async {
    ticks.add(null);
    await Future<void>.delayed(Duration.zero);
  }

  test('counts down from the server deadline and expires', () async {
    await cubit.load();
    expect(cubit.state.left, const Duration(seconds: 3));
    await tick();
    expect(cubit.state.left, const Duration(seconds: 2));
    await tick();
    await tick();
    expect(
      [cubit.state.left, cubit.state.outcome],
      [Duration.zero, RequestOutcome.expired],
    );
    expect(ticks.hasListener, isFalse);
  });

  test('a request without a deadline does not count down', () async {
    repo.json = booking(status: 'requested');
    await cubit.load();
    expect([cubit.state.left, cubit.state.outcome], [null, null]);
    expect(ticks.hasListener, isFalse);
  });

  test('answered or late requests open as expired', () async {
    repo.json = booking(deadline: '2026-10-09T05:00:00Z');
    await cubit.load();
    expect(cubit.state.outcome, RequestOutcome.expired);
    repo.json = booking(status: 'requested', deadline: '2026-10-09T03:59:00Z');
    await cubit.load();
    expect(cubit.state.outcome, RequestOutcome.expired);
  });

  test('a failed load is shown', () async {
    repo.fail = const NetworkFailure();
    await cubit.load();
    expect(cubit.state.view, isA<ViewFailure<Booking>>());
  });

  test('accepting succeeds or explains why not', () async {
    await cubit.load();
    repo.fail = const ApiFailure('ACTIVE_JOB_EXISTS', status: 409);
    await cubit.accept();
    expect(
      [cubit.state.failure!.code, cubit.state.outcome, cubit.state.busy],
      ['ACTIVE_JOB_EXISTS', null, false],
    );
    expect(ticks.hasListener, isTrue);
    repo.fail = null;
    await cubit.accept();
    expect(
      [cubit.state.outcome, cubit.state.failure],
      [RequestOutcome.accepted, null],
    );
    expect(ticks.hasListener, isFalse);
  });

  test('a request answered elsewhere turns into the expired state', () async {
    await cubit.load();
    repo.fail = const ApiFailure('ACCEPT_DEADLINE_PASSED', status: 409);
    await cubit.accept();
    expect(
      [cubit.state.outcome, cubit.state.failure],
      [RequestOutcome.expired, null],
    );
  });

  test('rejecting sends the reason and note', () async {
    await cubit.load();
    await cubit.reject(RejectInputReasonEnum.tooFar, 'Across the river');
    expect(cubit.state.outcome, RequestOutcome.rejected);
    expect(repo.calls.last, 'reject too_far Across the river');
  });

  test('the default ticker is a one-second timer', () {
    final own = RequestCubit(repo, 'b1', now: () => _now);
    expect(own.state.view, isA<ViewLoading<Booking>>());
    return own.close();
  });
}
