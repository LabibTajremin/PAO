import 'package:pao_api/pao_api.dart';

/// Services offered and where (M33).
class ServiceArea {
  /// Creates the setup.
  const ServiceArea({
    required this.options,
    required this.selected,
    required this.experienceYears,
    required this.radiusM,
    this.homeBase,
  });

  /// Published services the provider can offer.
  final List<ServiceRef> options;

  /// IDs of the services offered.
  final Set<String> selected;

  /// Years of experience.
  final int experienceYears;

  /// Working radius in metres.
  final int radiusM;

  /// Where the provider starts from.
  final Point? homeBase;

  /// A copy with changes.
  ServiceArea copyWith({
    Set<String>? selected,
    int? radiusM,
    Point? homeBase,
  }) => ServiceArea(
    options: options,
    selected: selected ?? this.selected,
    experienceYears: experienceYears,
    radiusM: radiusM ?? this.radiusM,
    homeBase: homeBase ?? this.homeBase,
  );
}

/// Reads and changes services and area through the enrolment steps.
abstract interface class ServiceAreaRepository {
  /// The current setup and the catalog to choose from.
  Future<ServiceArea> load();

  /// Saves services and experience.
  Future<void> saveServices(Set<String> serviceIds, int experienceYears);

  /// Saves home base and working radius.
  Future<void> saveArea(Point homeBase, int radiusM);
}
