import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pao_api/pao_api.dart';

/// The partner verification gate (PRD §8.5): until Level 1, or with an expired
/// document, only enrolment and verification screens are open.
class ProviderGate extends ChangeNotifier {
  /// Creates the gate reading through [api].
  ProviderGate(Dio api) : _api = ProviderEnrolmentApi(api);

  final ProviderEnrolmentApi _api;
  VerificationStatus? _status;

  /// The last loaded status.
  VerificationStatus? get status => _status;

  /// Whether the provider may use the working screens.
  bool get cleared => _status?.canReceiveBookings ?? false;

  /// Reloads the status; a failure keeps the previous one.
  Future<void> load() async {
    try {
      _status = (await _api.getVerificationStatus()).data;
      notifyListeners();
    } on DioException {
      return;
    }
  }

  /// Forgets the status, e.g. on sign-out.
  void clear() {
    _status = null;
    notifyListeners();
  }
}
