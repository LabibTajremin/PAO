import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// What the customer typed and pinned for an address (C06, C25).
class AddressDraft {
  /// Creates a draft.
  const AddressDraft({
    required this.label,
    required this.line1,
    required this.point,
    this.line2 = '',
    this.area = '',
  });

  /// Home, office or other.
  final AddressLabel label;

  /// House and road.
  final String line1;

  /// Floor, flat or landmark.
  final String line2;

  /// Neighbourhood.
  final String area;

  /// The pin.
  final GeoPoint point;
}

/// Whether [line1] fits the API's 3–200 characters once trimmed.
bool validLine1(String line1) {
  final n = line1.trim().length;
  return n >= 3 && n <= 200;
}

/// Saved addresses and the launch-area check (C-02).
abstract interface class AddressRepository {
  /// The saved addresses.
  Future<List<Address>> list();

  /// Saves a new address; the first one becomes the default.
  Future<Address> create(AddressDraft draft);

  /// Replaces the address [id], keeping whether it is the default.
  Future<Address> update(String id, AddressDraft draft, {bool? isDefault});

  /// Makes [id] the default address.
  Future<void> makeDefault(String id);

  /// Whether PAO works at [point].
  Future<ServiceAreaCheck> coverage(GeoPoint point);
}

/// The default address of [items], else the first, else null.
Address? defaultOf(List<Address> items) {
  for (final a in items) {
    if (a.isDefault ?? false) return a;
  }
  return items.isEmpty ? null : items.first;
}
