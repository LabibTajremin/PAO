import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/home/domain/home_repository.dart';

/// [HomeRepository] on the PAO API.
class ApiHomeRepository implements HomeRepository {
  /// Creates the repository.
  ApiHomeRepository(Dio api) : _api = ProviderJobsApi(api);

  final ProviderJobsApi _api;

  // The server's default; used when the presence reply leaves it out.
  static const _defaultInterval = 30;

  @override
  Future<HomeSummary> summary() async {
    final earnings = _api.getEarningsSummary(period: 'day');
    final requests = _api.listProviderJobs(tab: 'requests');
    final jobs = _api.listProviderJobs(tab: 'upcoming');
    // Future.wait rethrows the first original error, so an offline device
    // still shows the offline message.
    await Future.wait([earnings, requests, jobs]);
    final today = (await earnings).data!;
    return HomeSummary(
      earnedToday: today.total,
      jobsToday: today.jobs,
      requests: (await requests).data!.items,
      active: activeJob((await jobs).data!.items),
    );
  }

  @override
  Future<Duration> goOnline(GeoPoint at) async {
    final res = await _api.goOnline(heartbeatInput: _input(at));
    return Duration(
      seconds: res.data!.heartbeatIntervalSeconds ?? _defaultInterval,
    );
  }

  @override
  Future<void> goOffline() => _api.goOffline();

  @override
  Future<void> heartbeat(GeoPoint at) =>
      _api.sendHeartbeat(heartbeatInput: _input(at));

  HeartbeatInput _input(GeoPoint at) => HeartbeatInput(
    location: Point(lat: at.lat, lng: at.lng),
  );
}
