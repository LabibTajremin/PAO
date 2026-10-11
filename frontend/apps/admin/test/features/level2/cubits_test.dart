import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_admin/features/level2/presentation/provider_search.dart';
import 'package:pao_admin/features/level2/presentation/schedule_cubit.dart';
import 'package:pao_admin/features/level2/presentation/session_cubit.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

import 'fixtures.dart';

final _result = Level2ResultInput(
  result: Level2Result.pass,
  checklist: [
    Level2ResultInputChecklistInner(item: 'Safe wiring', passed: true),
  ],
);

SessionDetail? _detail(SessionCubit c) => switch (c.state.view) {
  ViewData(:final data) => data,
  _ => null,
};

void main() {
  late FakeLevel2Repository repo;

  setUp(() => repo = FakeLevel2Repository());

  group('SessionCubit', () {
    test(
      'an open session loads with the checklist, a closed one without',
      () async {
        final cubit = SessionCubit(repo, sessionId);
        await cubit.record(_result);
        expect(repo.calls, isEmpty);
        await cubit.load();
        expect(_detail(cubit)!.template.single.en, 'Safe wiring');
        expect(_detail(cubit)!.row.providerName, 'Rahim Uddin');
        repo.current = Level2Session.fromJson(sessionJson(status: 'completed'));
        await cubit.load();
        expect(_detail(cubit)!.template, isEmpty);
        await cubit.close();
      },
    );

    test('recording keeps the names and marks the drawer recorded', () async {
      final cubit = SessionCubit(repo, sessionId);
      await cubit.load();
      await cubit.record(_result);
      expect(cubit.state.recorded, isTrue);
      expect(_detail(cubit)!.row.session.result, Level2Result.pass);
      expect(_detail(cubit)!.row.providerName, 'Rahim Uddin');
      expect(repo.calls.single, _result);
      await cubit.close();
    });

    test('failures show on load and on record', () async {
      final cubit = SessionCubit(repo, sessionId);
      await cubit.load();
      repo.error = const ApiFailure('SESSION_CLOSED', status: 409);
      await cubit.record(_result);
      expect(cubit.state.failure!.code, 'SESSION_CLOSED');
      expect(_detail(cubit), isNotNull);
      await cubit.load();
      expect(cubit.state.view, isA<ViewFailure<SessionDetail>>());
      await cubit.close();
    });

    test('results arriving after close are dropped', () async {
      for (final error in [null, const NetworkFailure()]) {
        final loading = SessionCubit(repo..error = error, sessionId);
        final load = loading.load();
        await loading.close();
        await load;
        final recording = SessionCubit(repo..error = null, sessionId);
        await recording.load();
        repo.error = error;
        final record = recording.record(_result);
        await recording.close();
        await record;
        expect(recording.state.busy, isTrue);
      }
    });
  });

  test('ScheduleCubit books, fails and ignores late replies', () async {
    final cubit = ScheduleCubit(repo);
    final booking = Level2Booking(
      providerId: providerId,
      serviceId: serviceId,
      at: DateTime.utc(2026, 10, 12, 4),
      location: 'Gulshan',
    );
    await cubit.submit(booking);
    expect(cubit.state.booked!.id, sessionId);
    repo.error = const ApiFailure('LEVEL2_COOLING_OFF', status: 409);
    await cubit.submit(booking);
    expect(cubit.state.failure!.code, 'LEVEL2_COOLING_OFF');
    for (final error in [null, const NetworkFailure()]) {
      final late = ScheduleCubit(repo..error = error);
      final submit = late.submit(booking);
      await late.close();
      await submit;
      expect(late.state.busy, isTrue);
    }
    await cubit.close();
  });

  test(
    'ProviderSearchCubit searches, skips blanks and reports failures',
    () async {
      final cubit = ProviderSearchCubit(repo, level: 1);
      await cubit.search('  ');
      expect(cubit.state, isNull);
      await cubit.search('rahim');
      expect(repo.calls.single, 'providers rahim 1');
      expect(cubit.state, isA<ViewData<List<AdminProviderSummary>>>());
      repo.error = const NetworkFailure();
      await cubit.search('karim');
      expect(cubit.state, isA<ViewFailure<List<AdminProviderSummary>>>());
      for (final error in [null, const NetworkFailure()]) {
        final late = ProviderSearchCubit(repo..error = error);
        final search = late.search('x');
        await late.close();
        await search;
        expect(late.state, isA<ViewLoading<List<AdminProviderSummary>>>());
      }
      await cubit.close();
    },
  );
}
