import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/providers/domain/providers_repository.dart';
import 'package:pao_customer/features/providers/presentation/provider_labels.dart';
import 'package:pao_customer/features/providers/presentation/providers_cubit.dart';
import 'package:pao_customer/l10n/generated/customer_localizations_bn.dart';
import 'package:pao_customer/l10n/generated/customer_localizations_en.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_ui/pao_ui.dart';

import '../service/fixtures.dart';
import 'fixtures.dart';

ProviderCard _card(
  String id, {
  String badge = 'verified',
  double rating = 4.8,
}) => ProviderCard.fromJson(card(id, id, badge: badge, rating: rating));

class _Repo implements ProvidersRepository {
  final sorts = <ProviderSort>[];
  final pages = <String?, NearbyPage>{};

  @override
  Future<Address?> searchAddress() async => null;

  @override
  Future<NearbyPage> nearby({
    required BookingDraft draft,
    required String addressId,
    required ProviderSort sort,
    String? cursor,
  }) async {
    sorts.add(sort);
    return pages[cursor]!;
  }

  @override
  Future<ProviderOverview> overview(String id) => throw UnimplementedError();

  @override
  Future<Paged<Review>> reviews(String id, {String? cursor}) =>
      throw UnimplementedError();
}

void main() {
  test('filters keep top rated or pro providers', () {
    const all = ProviderQuery();
    const strict = ProviderQuery(topRated: true, proOnly: true);
    expect(all.keeps(_card('a', rating: 3)), isTrue);
    expect(strict.keeps(_card('a', rating: 4.5)), isFalse);
    expect(strict.keeps(_card('a', badge: 'verified_pro', rating: 4)), isTrue);
    expect(
      strict.keeps(_card('a', badge: 'verified_pro', rating: 3.9)),
      isFalse,
    );
  });

  test('the list skips pages the filters empty', () async {
    final summary = PriceSummary.fromJson(
      (nearby(const [])['priceSummary']! as Map).cast<String, Object?>(),
    );
    final repo = _Repo()
      ..pages[null] = NearbyPage([_card('a', rating: 3)], summary, 'c2')
      ..pages['c2'] = NearbyPage([_card('b')], summary, 'c3')
      ..pages['c3'] = NearbyPage(const [], summary);
    final cubit = ProvidersCubit(
      repo,
      draft: const BookingDraft(serviceId: electricianId, items: {fanId: 2}),
      addressId: 'a1',
    );
    await cubit.load();
    expect(cubit.state.items.single.id, 'a');
    expect(cubit.summary!.total, 100000);
    await cubit.apply(
      const ProviderQuery(sort: ProviderSort.rating, topRated: true),
    );
    expect(cubit.query.topRated, isTrue);
    expect(cubit.state.items.single.id, 'b');
    expect(cubit.state.next, 'c3');
    await cubit.more();
    expect(cubit.state.items.single.id, 'b');
    expect(repo.sorts.last, ProviderSort.rating);
  });

  test('labels for badges, distances and tags', () {
    final t = CustomerL10nEn();
    expect(
      [for (final b in Badge.values) badgeLabel(t, b)],
      ['Not verified', 'Verified', 'PAO Verified Pro'],
    );
    expect(
      [for (final b in Badge.values) badgeTone(b)],
      [PaoTone.neutral, PaoTone.success, PaoTone.accent],
    );
    expect(distanceText(t, 800, 'en'), '800 m away');
    expect(distanceText(t, 1250, 'en'), '1.3 km away');
    expect(distanceText(CustomerL10nBn(), 1250, 'bn'), '১.৩ কিমি দূরে');
    expect({
      for (final tag in ReviewTag.values) tagLabel(t, tag),
    }, hasLength(ReviewTag.values.length));
    expect(photoOf(null), isNull);
    expect(photoOf('https://x/p.jpg'), isA<NetworkImage>());
  });
}
