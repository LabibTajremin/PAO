import 'package:pao_api/pao_api.dart';

/// Key counts and bookings per day for the dashboard (A-09).
abstract interface class DashboardRepository {
  /// Loads the current figures.
  Future<Dashboard> load();
}
