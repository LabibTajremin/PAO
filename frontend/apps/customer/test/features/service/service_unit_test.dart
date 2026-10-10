import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/service/domain/selection.dart';
import 'package:pao_customer/features/service/presentation/selection_cubit.dart';
import 'package:pao_customer/features/service/presentation/service_footer.dart';
import 'package:pao_customer/l10n/generated/customer_localizations_en.dart';
import 'package:pao_customer/shared/price_units.dart';

import 'fixtures.dart';

void main() {
  final electrician = Service.fromJson(service());
  final hire = Service.fromJson(driver());
  final now = DateTime.utc(2026, 10, 9, 4);

  test('totals, drafts and what blocks going on', () {
    expect(bookable(electrician), hasLength(2));
    expect(
      bookable(Service.fromJson(service()..remove('subServices'))),
      isEmpty,
    );
    const picked = Selection(items: {fanId: 2, switchId: 1});
    expect(totalOf(electrician, picked.items), 130000);
    expect(
      problemOf(electrician, const Selection(), now),
      SelectionProblem.empty,
    );
    expect(problemOf(electrician, picked, now), isNull);
    const duty = Selection(items: {hourlyId: 4});
    expect(problemOf(hire, duty, now), SelectionProblem.noStart);
    final early = Selection(
      items: duty.items,
      day: DateTime(2026, 10, 9),
      minutes: 9 * 60,
    );
    expect(early.start, DateTime.utc(2026, 10, 9, 3));
    expect(problemOf(hire, early, now), SelectionProblem.pastStart);
    final later = Selection(
      items: duty.items,
      day: DateTime(2026, 10, 9),
      minutes: 11 * 60,
    );
    expect(problemOf(hire, later, now), isNull);
    expect(draftOf(hire, later).toQuery(), {
      'service': driverId,
      'items': '$hourlyId:4',
      'at': '2026-10-09T05:00:00.000Z',
    });
    expect(draftOf(electrician, picked).scheduledAt, isNull);
  });

  test('the selection cubit sets quantities, a duty and the start', () {
    final cubit = SelectionCubit()
      ..quantity(fanId, 2)
      ..quantity(switchId, 1)
      ..quantity(fanId, 0);
    expect(cubit.state.items, {switchId: 1});
    cubit
      ..only(hourlyId, 3)
      ..day(DateTime(2026, 10, 10))
      ..time(90);
    expect(cubit.state.items, {hourlyId: 3});
    expect(cubit.state.start, DateTime.utc(2026, 10, 9, 19, 30));
  });

  test('units and problems have words', () {
    final t = CustomerL10nEn();
    expect(
      [for (final u in PriceUnit.values) unitLabel(t, u)],
      ['per job', 'per unit', 'per hour', 'per day'],
    );
    expect(
      [for (final p in SelectionProblem.values) problemText(t, p)],
      [
        'Choose at least one item to continue.',
        'Choose when the driver should start.',
        'Choose a start time in the future.',
      ],
    );
  });
}
