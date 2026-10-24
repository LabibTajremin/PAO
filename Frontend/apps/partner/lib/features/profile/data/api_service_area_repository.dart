import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/profile/domain/service_area_repository.dart';

/// [ServiceAreaRepository] on the profile, catalog and enrolment endpoints.
class ApiServiceAreaRepository implements ServiceAreaRepository {
  /// Creates the repository.
  ApiServiceAreaRepository(Dio dio)
    : _api = ProviderApi(dio),
      _enrolment = ProviderEnrolmentApi(dio);

  /// Radius offered when none is saved yet.
  static const defaultRadiusM = 8000;

  final ProviderApi _api;
  final ProviderEnrolmentApi _enrolment;

  @override
  Future<ServiceArea> load() async {
    final p = (await _api.getProviderProfile()).data!;
    final catalog = await _api.getProviderCatalog();
    return ServiceArea(
      options: [
        for (final category in catalog.data!.categories)
          for (final s in category.services)
            if (s.published) ServiceRef(id: s.id, name: s.name),
      ],
      selected: {for (final s in p.services) s.id},
      experienceYears: p.experienceYears,
      radiusM: p.workingRadiusM ?? defaultRadiusM,
      homeBase: p.homeBase,
    );
  }

  @override
  Future<void> saveServices(Set<String> serviceIds, int experienceYears) =>
      _enrolment.saveServicesStep(
        servicesInput: ServicesInput(
          serviceIds: serviceIds.toList(),
          experienceYears: experienceYears,
        ),
      );

  @override
  Future<void> saveArea(Point homeBase, int radiusM) => _enrolment.saveAreaStep(
    serviceAreaInput: ServiceAreaInput(
      homeBase: homeBase,
      workingRadiusM: radiusM,
    ),
  );
}
