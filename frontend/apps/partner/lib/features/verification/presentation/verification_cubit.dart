import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/verification/domain/verification.dart';

/// Loads M14 and refreshes it together with the verification gate.
class VerificationCubit extends LoadCubit<VerificationSummary> {
  /// Creates the cubit; [reloadGate] reloads the app's gate.
  VerificationCubit(VerificationRepository repo, {required this.reloadGate})
    : super(repo.load);

  /// Reloads the gate so an approval opens the app.
  final Future<void> Function() reloadGate;

  /// Pull-to-refresh.
  Future<void> pull() => Future.wait([refresh(), reloadGate()]);
}
