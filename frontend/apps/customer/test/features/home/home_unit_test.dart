import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/home/domain/home_repository.dart';
import 'package:pao_customer/features/home/presentation/home_cubit.dart';
import 'package:pao_customer/features/home/presentation/home_parts.dart';
import 'package:pao_customer/l10n/generated/customer_localizations_en.dart';
import 'package:pao_customer/shared/catalog_icons.dart';

import '../service/fixtures.dart';

class _Repo implements HomeRepository {
  int loads = 0;
  AppFailure? error;
  final defaults = <String>[];

  @override
  Future<HomeData> load() async {
    loads++;
    return const HomeData(addresses: [], categories: []);
  }

  @override
  Future<void> makeDefault(String addressId) async {
    if (error case final AppFailure e) throw e;
    defaults.add(addressId);
  }
}

BookingSummary _booking(String status) => BookingSummary.fromJson({
  'id': 'b1',
  'number': 'PAO-1',
  'status': status,
  'serviceName': named('Electrician'),
  'total': 100,
  'createdAt': '2026-10-09T04:00:00Z',
});

void main() {
  test('only published, non-empty categories show, in order', () {
    final shown = publishedOf(CatalogTree.fromJson(catalog()));
    expect(shown.map((c) => c.name.en), ['Repairs', 'Beauty']);
    expect(shown.last.services.single.id, salonId);
  });

  test('the first running booking is active', () {
    final done = _booking('completed');
    final waiting = _booking('requested');
    expect(activeOf([done]), isNull);
    expect(activeOf([done, waiting]), waiting);
    expect(activePart(BookingStatus.requested), 'waiting');
    expect(activePart(BookingStatus.arrived), 'live');
    final t = CustomerL10nEn();
    expect(
      [
        for (final s in [
          BookingStatus.accepted,
          BookingStatus.onTheWay,
          BookingStatus.arrived,
          BookingStatus.inProgress,
        ])
          activeStatusText(t, s),
      ],
      [
        'The provider accepted',
        'The provider is on the way',
        'The provider has arrived',
        'The job is in progress',
      ],
    );
  });

  test('switching the address reloads, or reports why it failed', () async {
    final repo = _Repo();
    final cubit = HomeCubit(repo);
    expect(await cubit.switchTo('a2'), isNull);
    expect(
      [repo.defaults, repo.loads],
      [
        ['a2'],
        1,
      ],
    );
    repo.error = const NetworkFailure();
    expect((await cubit.switchTo('a3'))!.code, 'NETWORK');
    expect(repo.loads, 1);
    expect(const HomeData(addresses: [], categories: []).current, isNull);
  });

  test('catalog icons fall back to a tool', () {
    expect(catalogIcon('bolt'), Icons.bolt);
    expect(catalogIcon('unknown'), Icons.handyman_outlined);
  });
}
