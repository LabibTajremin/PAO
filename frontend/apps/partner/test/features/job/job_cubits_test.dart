import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/job/domain/job_repository.dart';
import 'package:pao_partner/features/job/presentation/extras_cubit.dart';
import 'package:pao_partner/features/job/presentation/job_cubit.dart';
import 'package:pao_partner/features/job/presentation/rate_cubit.dart';

import 'job_fixtures.dart';

Booking _booking(String status, {Map<String, Object?>? extras}) =>
    Booking.fromJson(booking(status: status, pendingExtras: extras));

class _Repo implements JobRepository {
  Booking current = _booking('accepted');
  AppFailure? fail;
  final calls = <String>[];
  CustomerReview? reviewed;

  Future<Booking> _act(String call, [Booking? next]) async {
    calls.add(call);
    if (fail != null) throw fail!;
    return current = next ?? current;
  }

  @override
  Future<Booking> job(String id) => _act('job');

  @override
  Future<Booking> onTheWay(String id) =>
      _act('on-the-way', _booking('on_the_way'));

  @override
  Future<Booking> arrived(String id) => _act('arrived', _booking('arrived'));

  @override
  Future<Booking> cancel(
    String id,
    ProviderCancelInputReasonEnum reason,
    String? note,
  ) => _act('cancel $reason $note', _booking('cancelled'));

  @override
  Future<Booking> start(String id, String code) =>
      _act('start $code', _booking('in_progress'));

  @override
  Future<List<SubService>> extrasFor(String serviceId) async {
    calls.add('extras-for $serviceId');
    return [
      SubService.fromJson(subService('a', price: 10000)),
      SubService.fromJson(subService('b', price: 25000)),
    ];
  }

  @override
  Future<Booking> proposeExtras(String id, Map<String, int> quantities) => _act(
    'propose $quantities',
    _booking('in_progress', extras: proposal('pending')),
  );

  @override
  Future<Booking> complete(String id) =>
      _act('complete', _booking('completed'));

  @override
  Future<void> review(String id, CustomerReview review) async {
    await _act('review');
    reviewed = review;
  }
}

void main() {
  test('job cubit loads and walks the status actions', () async {
    final repo = _Repo();
    final cubit = JobCubit(repo, 'b1');
    expect(cubit.state.booking, isNull);
    await cubit.load();
    expect(cubit.state.booking!.status, BookingStatus.accepted);
    await cubit.advance();
    expect(cubit.state.booking!.status, BookingStatus.onTheWay);
    expect(cubit.state.done, isTrue);
    await cubit.advance();
    await cubit.start('4821');
    await cubit.complete();
    expect(cubit.state.booking!.status, BookingStatus.completed);
    await cubit.cancel(ProviderCancelInputReasonEnum.other, 'late');
    expect(repo.calls, [
      'job',
      'on-the-way',
      'arrived',
      'start 4821',
      'complete',
      'cancel other late',
    ]);
    await cubit.close();
  });

  test('job cubit keeps the job and reports failed actions', () async {
    final repo = _Repo();
    final cubit = JobCubit(repo, 'b1');
    await cubit.load();
    repo.fail = const ApiFailure('START_CODE_INVALID', status: 422);
    await cubit.start('0000');
    expect(cubit.state.failure!.code, 'START_CODE_INVALID');
    expect(
      [cubit.state.booking, cubit.state.done, cubit.state.busy],
      [isNotNull, false, false],
    );
    await cubit.refresh();
    expect(cubit.state.view, isA<ViewFailure<Booking>>());
    await cubit.close();
  });

  test('extras cubit picks quantities and proposes them', () async {
    final repo = _Repo()..current = _booking('in_progress');
    final cubit = ExtrasCubit(repo, 'b1');
    expect(cubit.state.addedTotal, 0);
    await cubit.load();
    final data = (cubit.state.view as ViewData<ExtrasData>).data;
    expect([data.options.length, data.waiting], [2, false]);
    cubit
      ..pick('a', 2)
      ..pick('b', 1)
      ..pick('b', 0);
    expect(cubit.state.quantities, {'a': 2});
    expect(cubit.state.addedTotal, 20000);
    repo.fail = const ApiFailure('EXTRAS_PENDING', status: 409);
    await cubit.submit();
    expect(
      [cubit.state.failure!.code, cubit.state.quantities],
      [
        'EXTRAS_PENDING',
        {'a': 2},
      ],
    );
    repo.fail = null;
    await cubit.submit();
    final sent = (cubit.state.view as ViewData<ExtrasData>).data;
    expect([sent.waiting, cubit.state.quantities], [true, isEmpty]);
    expect(repo.calls, contains('propose {a: 2}'));
    await cubit.close();
  });

  test('extras cubit shows a failed load', () async {
    final repo = _Repo()..fail = const NetworkFailure();
    final cubit = ExtrasCubit(repo, 'b1');
    await cubit.load();
    expect(
      (cubit.state.view as ViewFailure<ExtrasData>).failure.code,
      'NETWORK',
    );
    await cubit.close();
  });

  test('rate cubit needs a star, toggles tags and sends', () async {
    final repo = _Repo();
    final cubit = RateCubit(repo, 'b1');
    await cubit.submit('');
    expect(repo.calls, isEmpty);
    cubit
      ..rate(4)
      ..toggle(ReviewTag.polite)
      ..toggle(ReviewTag.rude)
      ..toggle(ReviewTag.rude);
    expect(cubit.state.tags, {ReviewTag.polite});
    repo.fail = const NetworkFailure();
    await cubit.submit(' ok ');
    expect([cubit.state.failure!.code, cubit.state.done], ['NETWORK', false]);
    repo.fail = null;
    await cubit.submit(' Kind and clear ');
    expect(cubit.state.done, isTrue);
    expect(repo.reviewed!.stars, 4);
    expect(repo.reviewed!.comment, 'Kind and clear');
    expect(repo.reviewed!.tags, {ReviewTag.polite});
    await cubit.close();
  });
}
