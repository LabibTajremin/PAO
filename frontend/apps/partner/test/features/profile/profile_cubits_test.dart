import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/profile/domain/profile_repository.dart';
import 'package:pao_partner/features/profile/domain/service_area_repository.dart';
import 'package:pao_partner/features/profile/presentation/language_cubit.dart';
import 'package:pao_partner/features/profile/presentation/profile_cubit.dart';
import 'package:pao_partner/features/profile/presentation/profile_labels.dart';
import 'package:pao_partner/features/profile/presentation/services_cubit.dart';

import '../jobs/fixtures.dart';
import 'fixtures.dart';

class _Profiles implements ProfileRepository {
  AppFailure? failUpload;
  final updates = <ProviderProfileUpdate>[];

  @override
  Future<ProfileOverview> overview() async => ProfileOverview(
    ProviderProfile.fromJson(profile()),
    RatingBreakdown.fromJson(rating()),
  );

  @override
  Future<ProviderProfile> update(ProviderProfileUpdate change) async {
    updates.add(change);
    return ProviderProfile.fromJson({...profile(), 'bio': ?change.bio});
  }

  @override
  Future<String> uploadPhoto(Uint8List bytes) async {
    if (failUpload != null) throw failUpload!;
    return 'media-1';
  }

  @override
  Future<Paged<Review>> reviews({String? cursor}) async => const Paged([]);

  @override
  Future<VerificationStatus> verification() async =>
      VerificationStatus.fromJson(verificationStatus());
}

class _Areas implements ServiceAreaRepository {
  final saved = <Object>[];

  @override
  Future<ServiceArea> load() async => ServiceArea(
    options: [
      for (var i = 0; i < 7; i++)
        ServiceRef(
          id: 's$i',
          name: LocalizedText(en: 'S$i', bn: 'স$i'),
        ),
    ],
    selected: {'s0'},
    experienceYears: 3,
    radiusM: 5000,
  );

  @override
  Future<void> saveServices(
    Set<String> serviceIds,
    int experienceYears,
  ) async => saved.add('${serviceIds.join(',')} $experienceYears');

  @override
  Future<void> saveArea(Point homeBase, int radiusM) async =>
      saved.add('${homeBase.lat} $radiusM');
}

void main() {
  test('a profile photo is shown only when there is one', () {
    expect(photoOf(null), isNull);
    expect(
      (photoOf('https://cdn.test/p.jpg')! as NetworkImage).url,
      'https://cdn.test/p.jpg',
    );
  });

  test('profile cubit saves the bio and photo with the language', () async {
    final repo = _Profiles();
    final cubit = ProfileCubit(repo);
    await cubit.load();
    expect(await cubit.saveBio('  Fixes fans.  '), isNull);
    expect(
      (cubit.state as ViewData<ProfileOverview>).data.profile.bio,
      'Fixes fans.',
    );
    expect(await cubit.changePhoto(null), isNull);
    expect(await cubit.changePhoto(tinyPng), isNull);
    expect(repo.updates.map((u) => u.toJson()), [
      {'bio': 'Fixes fans.', 'language': 'en'},
      {'photoMediaId': 'media-1', 'language': 'en'},
    ]);
    repo.failUpload = const NetworkFailure();
    expect((await cubit.changePhoto(tinyPng))!.code, 'NETWORK');
    expect(repo.updates, hasLength(2));
    await cubit.close();
  });

  test('services cubit toggles up to five services and saves', () async {
    final repo = _Areas();
    final cubit = ServicesCubit(repo);
    await cubit.load();
    ServiceArea area() => (cubit.state as ViewData<ServiceArea>).data;
    for (var i = 0; i < 7; i++) {
      cubit.toggle('s$i');
    }
    expect(area().selected, {'s1', 's2', 's3', 's4', 's5'});
    cubit
      ..setRadius(12000)
      ..moveHome(Point(lat: 23.8, lng: 90.4));
    expect(
      [area().radiusM, area().homeBase!.lat, area().options.length],
      [12000, 23.8, 7],
    );
    expect(await cubit.save(4), isNull);
    expect(repo.saved, ['s1,s2,s3,s4,s5 4', '23.8 12000']);
    await cubit.close();
  });

  test(
    'language cubit keeps the choice locally even if upload fails',
    () async {
      final kept = <String>[];
      var fail = true;
      final cubit = LanguageCubit(
        keep: (code) async => kept.add(code),
        upload: (code) async {
          if (fail) throw const NetworkFailure();
        },
      );
      await cubit.select('bn');
      expect(
        [kept, cubit.state!.code],
        [
          ['bn'],
          'NETWORK',
        ],
      );
      fail = false;
      await cubit.select('en');
      expect(cubit.state, isNull);
      final closing = cubit.select('bn');
      await cubit.close();
      await closing;
      expect(kept, ['bn', 'en', 'bn']);
    },
  );
}
