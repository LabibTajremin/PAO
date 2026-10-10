import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/profile/domain/service_area_repository.dart';

/// Loads and edits services and service area (M33).
class ServicesCubit extends LoadCubit<ServiceArea> {
  /// Creates the cubit; call [load] to start.
  ServicesCubit(this._repo) : super(_repo.load);

  /// Most services a provider may offer (ServicesInput limit).
  static const maxServices = 5;

  final ServiceAreaRepository _repo;

  ServiceArea get _area => (state as ViewData<ServiceArea>).data;

  /// Adds or removes the service [id], up to [maxServices].
  void toggle(String id) {
    final selected = {..._area.selected};
    if (!selected.remove(id)) {
      if (selected.length >= maxServices) return;
      selected.add(id);
    }
    emit(ViewData(_area.copyWith(selected: selected)));
  }

  /// Sets the working radius.
  void setRadius(int metres) => emit(ViewData(_area.copyWith(radiusM: metres)));

  /// Moves the home base to [point].
  void moveHome(Point point) => emit(ViewData(_area.copyWith(homeBase: point)));

  /// Saves services with [experienceYears], then the area.
  Future<AppFailure?> save(int experienceYears) {
    final area = _area;
    return attempt(() async {
      await _repo.saveServices(area.selected, experienceYears);
      await _repo.saveArea(area.homeBase!, area.radiusM);
    });
  }
}
