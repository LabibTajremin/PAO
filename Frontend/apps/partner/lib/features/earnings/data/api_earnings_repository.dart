import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/earnings/domain/earnings_repository.dart';

/// [EarningsRepository] on the PAO API.
class ApiEarningsRepository implements EarningsRepository {
  /// Creates the repository.
  ApiEarningsRepository(Dio api) : _api = ProviderJobsApi(api);

  final ProviderJobsApi _api;

  // The server owns the period boundaries (Saturday weeks, Asia/Dhaka days), so
  // the job list reuses the dates of the summary instead of recomputing them.
  final _ranges = <EarningsPeriod, EarningsSummary>{};

  @override
  Future<EarningsSummary> summary(EarningsPeriod period) async =>
      _ranges[period] = (await _api.getEarningsSummary(period: period.value))
          .data!;

  @override
  Future<Paged<EarningsJob>> jobs(
    EarningsPeriod period, {
    String? cursor,
  }) async {
    final range = _ranges[period] ?? await summary(period);
    final res = await _api.listEarningsJobs(
      from: range.from,
      to: range.to,
      cursor: cursor,
    );
    return Paged(res.data!.items, res.data!.nextCursor);
  }
}
