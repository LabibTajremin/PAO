import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/domain/address_repository.dart';
import 'package:pao_customer/features/location/domain/places.dart';

/// The address form (C06, C25).
class AddressFormState {
  /// Creates the state.
  const AddressFormState({
    required this.point,
    this.label = AddressLabel.home,
    this.coverage,
    this.place,
    this.locating = false,
    this.locateFailed = false,
    this.saving = false,
    this.invalidLine1 = false,
    this.failure,
    this.saved,
  });

  /// The pin.
  final GeoPoint point;

  /// Home, office or other.
  final AddressLabel label;

  /// Whether PAO works at the pin; null until checked.
  final ServiceAreaCheck? coverage;

  /// The last place found for the pin, used to fill in the fields.
  final Place? place;

  /// The device position is being read.
  final bool locating;

  /// The device position was unavailable.
  final bool locateFailed;

  /// The address is being saved.
  final bool saving;

  /// The first line is too short or too long.
  final bool invalidLine1;

  /// Why saving failed.
  final AppFailure? failure;

  /// The stored address once saved.
  final Address? saved;

  /// A copy with the given fields; the one-off flags reset.
  AddressFormState copyWith({
    GeoPoint? point,
    AddressLabel? label,
    ServiceAreaCheck? coverage,
    Place? place,
    bool locating = false,
    bool locateFailed = false,
    bool saving = false,
    bool invalidLine1 = false,
    AppFailure? failure,
    Address? saved,
  }) => AddressFormState(
    point: point ?? this.point,
    label: label ?? this.label,
    coverage: coverage ?? this.coverage,
    place: place ?? this.place,
    locating: locating,
    locateFailed: locateFailed,
    saving: saving,
    invalidLine1: invalidLine1,
    failure: failure,
    saved: saved,
  );
}

/// Moves the pin, checks the launch area and saves the address.
class AddressFormCubit extends Cubit<AddressFormState> {
  /// Creates the cubit; [editing] is the address being changed, if any.
  AddressFormCubit({
    required this._repo,
    required this._location,
    required this._places,
    this.language = 'en',
    this.editing,
  }) : super(
         AddressFormState(
           point: editing == null
               ? dhakaCentre
               : GeoPoint(editing.location.lat, editing.location.lng),
           label: editing?.label ?? AddressLabel.home,
         ),
       );

  final AddressRepository _repo;
  final LocationService _location;
  final PlacesService _places;

  /// Language of looked-up place names.
  final String language;

  /// The address being edited, if any.
  final Address? editing;

  /// Puts the pin at the device position and looks up its address.
  Future<void> locate() async {
    emit(state.copyWith(locating: true));
    final point = await _quietly(_location.current);
    if (point == null) return emit(state.copyWith(locateFailed: true));
    final place = await _quietly(
      () => _places.reverse(point, language: language),
    );
    if (place != null) emit(state.copyWith(place: place));
    await moveTo(point);
  }

  /// Uses a searched [place].
  Future<void> pick(Place place) async {
    emit(state.copyWith(place: place));
    await moveTo(place.point);
  }

  /// Moves the pin to [point] and checks whether PAO works there.
  Future<void> moveTo(GeoPoint point) async {
    emit(state.copyWith(point: point));
    // Unknown coverage must not block saving; the API checks it again.
    final check = await _quietly(() => _repo.coverage(point));
    if (!isClosed) emit(state.copyWith(coverage: check));
  }

  /// Chooses the [label].
  void choose(AddressLabel label) => emit(state.copyWith(label: label));

  /// Saves the address with the typed lines.
  Future<void> save({
    required String line1,
    String line2 = '',
    String area = '',
  }) async {
    if (!validLine1(line1)) return emit(state.copyWith(invalidLine1: true));
    emit(state.copyWith(saving: true));
    final draft = AddressDraft(
      label: state.label,
      line1: line1,
      line2: line2,
      area: area,
      point: state.point,
    );
    Address? saved;
    final failure = await attempt(() async {
      final e = editing;
      saved = e == null
          ? await _repo.create(draft)
          : await _repo.update(e.id, draft, isDefault: e.isDefault);
    });
    emit(state.copyWith(failure: failure, saved: saved));
  }

  /// Device position and place names are conveniences: when they fail the
  /// customer moves the pin or types the address instead.
  Future<T?> _quietly<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on Object {
      return null;
    }
  }
}
