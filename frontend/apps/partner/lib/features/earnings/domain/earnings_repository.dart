import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/jobs/domain/paged.dart';

/// What the provider earned (P-08).
abstract interface class EarningsRepository {
  /// Totals for the current [period] in Asia/Dhaka.
  Future<EarningsSummary> summary(EarningsPeriod period);

  /// Completed jobs with their amounts, newest first.
  Future<Paged<EarningsJob>> jobs({String? cursor});
}
