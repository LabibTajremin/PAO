import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/earnings/domain/earnings_repository.dart';
import 'package:pao_partner/features/jobs/domain/paged.dart';

/// [EarningsRepository] on the PAO API.
class ApiEarningsRepository implements EarningsRepository {
  /// Creates the repository.
  ApiEarningsRepository(Dio api) : _api = ProviderJobsApi(api);

  final ProviderJobsApi _api;

  @override
  Future<EarningsSummary> summary(EarningsPeriod period) async =>
      (await _api.getEarningsSummary(period: period.value)).data!;

  @override
  Future<Paged<EarningsJob>> jobs({String? cursor}) async {
    final res = await _api.listEarningsJobs(cursor: cursor);
    return Paged(res.data!.items, res.data!.nextCursor);
  }
}
