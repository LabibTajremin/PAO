import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/domain/address_repository.dart';
import 'package:pao_customer/features/location/domain/places.dart';
import 'package:pao_customer/features/location/presentation/address_form_cubit.dart';
import 'package:pao_customer/features/location/presentation/address_labels.dart';
import 'package:pao_customer/features/location/presentation/place_search_cubit.dart';
import 'package:pao_customer/shared/debouncer.dart';

import 'fixtures.dart';

class _Repo implements AddressRepository {
  final created = <AddressDraft>[];
  final updated = <(String, AddressDraft, bool?)>[];
  AppFailure? error;
  bool coverageFails = false;

  Address _stored(AddressDraft d) => Address(
    id: homeAddressId,
    label: d.label,
    line1: d.line1,
    location: Point(lat: d.point.lat, lng: d.point.lng),
    isDefault: true,
  );

  @override
  Future<List<Address>> list() async => const [];

  @override
  Future<Address> create(AddressDraft draft) async {
    if (error case final AppFailure e) throw e;
    created.add(draft);
    return _stored(draft);
  }

  @override
  Future<Address> update(
    String id,
    AddressDraft draft, {
    bool? isDefault,
  }) async {
    updated.add((id, draft, isDefault));
    return _stored(draft);
  }

  @override
  Future<void> makeDefault(String id) async {}

  @override
  Future<ServiceAreaCheck> coverage(GeoPoint point) async {
    if (coverageFails) throw const NetworkFailure();
    return ServiceAreaCheck(covered: point.lat > 23, areaName: 'Dhaka');
  }
}

class _Location implements LocationService {
  _Location([this.point]);

  final GeoPoint? point;
  bool fail = false;

  @override
  Future<GeoPoint?> current() async {
    if (fail) throw StateError('gps');
    return point;
  }
}

AddressFormCubit _cubit(
  _Repo repo, {
  GeoPoint? at,
  FakePlaces? places,
  Address? editing,
}) => AddressFormCubit(
  repo: repo,
  location: _Location(at),
  places: places ?? FakePlaces(),
  language: 'bn',
  editing: editing,
);

void main() {
  test('line 1 needs 3 to 200 characters; the default address wins', () {
    expect([validLine1(' ab '), validLine1('Road 5')], [false, true]);
    Address a(String id, {bool? isDefault}) => Address(
      id: id,
      label: AddressLabel.home,
      line1: 'x',
      location: Point(lat: 1, lng: 1),
      isDefault: isDefault,
    );
    expect(defaultOf(const []), isNull);
    expect(defaultOf([a('1'), a('2', isDefault: true)])!.id, '2');
    expect(defaultOf([a('1', isDefault: false), a('2')])!.id, '1');
  });

  test('locating moves the pin, names it and checks coverage', () async {
    final repo = _Repo();
    final cubit = _cubit(repo, at: const GeoPoint(23.7, 90.4));
    expect(cubit.state.point, dhakaCentre);
    await cubit.locate();
    expect(cubit.state.point.lat, 23.7);
    expect(cubit.state.place, gulshan);
    expect(cubit.state.coverage!.covered, isTrue);
    repo.coverageFails = true;
    await cubit.moveTo(const GeoPoint(10, 10));
    expect(cubit.state.coverage!.covered, isTrue, reason: 'last known kept');
    cubit.choose(AddressLabel.office);
    expect(cubit.state.label, AddressLabel.office);
  });

  test('no position, or a failing one, is reported', () async {
    final none = _cubit(_Repo());
    await none.locate();
    expect(none.state.locateFailed, isTrue);
    final places = FakePlaces()..fail = true;
    final location = _Location(const GeoPoint(23.7, 90.4))..fail = true;
    final failing = AddressFormCubit(
      repo: _Repo(),
      location: location,
      places: places,
    );
    await failing.locate();
    expect(failing.state.locateFailed, isTrue);
  });

  test('saving validates, reports failures and creates', () async {
    final repo = _Repo();
    final cubit = _cubit(repo);
    await cubit.pick(banani);
    expect(cubit.state.point, banani.point);
    await cubit.save(line1: 'ab');
    expect(cubit.state.invalidLine1, isTrue);
    repo.error = const NetworkFailure();
    await cubit.save(line1: 'Road 11');
    expect(cubit.state.failure!.code, 'NETWORK');
    repo.error = null;
    await cubit.save(line1: 'Road 11', line2: 'Flat 2', area: 'Banani');
    expect(cubit.state.saved!.line1, 'Road 11');
    expect(repo.created.single.area, 'Banani');
  });

  test('editing keeps the pin, label and default flag', () async {
    final repo = _Repo();
    final editing = Address.fromJson(address(label: 'office'));
    final cubit = _cubit(repo, editing: editing);
    expect(cubit.state.point.lat, 23.794);
    expect(cubit.state.label, AddressLabel.office);
    await cubit.save(line1: 'House 1, Road 1');
    expect(repo.updated.single.$1, homeAddressId);
    expect(repo.updated.single.$3, isTrue);
  });

  test('place search waits for a pause and needs 3 letters', () async {
    final places = FakePlaces();
    final cubit = PlaceSearchCubit(
      places,
      language: 'bn',
      delay: const Duration(milliseconds: 5),
    )..query('Ba');
    expect(cubit.state, isEmpty);
    cubit
      ..query('Bana')
      ..query('Banani');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(places.queries, ['bn:Banani']);
    expect(cubit.state, [banani]);
    places.fail = true;
    cubit.query('Gulshan');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cubit.state, isEmpty);
    cubit
      ..query('Gulshan 2')
      ..clear();
    await cubit.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(places.queries, hasLength(2));
  });

  test('a debouncer runs only the last action', () async {
    final ran = <int>[];
    final d = Debouncer(const Duration(milliseconds: 5))
      ..run(() => ran.add(1))
      ..run(() => ran.add(2));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    d
      ..run(() => ran.add(3))
      ..cancel();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(ran, [2]);
    expect(Debouncer().delay, const Duration(milliseconds: 300));
  });

  test('every label has an icon', () {
    expect({
      for (final l in AddressLabel.values) addressLabelIcon(l),
    }, hasLength(3));
  });

  test('without a maps key nothing is found', () async {
    const none = NoPlacesService();
    expect(await none.search('Banani'), isEmpty);
    expect(await none.reverse(dhakaCentre), isNull);
  });
}
