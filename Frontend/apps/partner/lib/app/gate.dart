import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// The partner verification gate (PRD §8.5): until Level 1, or with an expired
/// document, only enrolment and verification screens are open.
class ProviderGate extends ChangeNotifier {
  /// Creates the gate reading through [api]; the permissions given, if any,
  /// are reloaded whenever the provider crosses the gate.
  ProviderGate(Dio api, [this._permissions]) : _api = ProviderEnrolmentApi(api);

  final ProviderEnrolmentApi _api;
  final PermissionService? _permissions;
  VerificationStatus? _status;

  /// The last loaded status.
  VerificationStatus? get status => _status;

  /// Whether the provider may use the working screens.
  bool get cleared => _status?.canReceiveBookings ?? false;

  /// Reloads the status; a failure keeps the previous one.
  Future<void> load() async {
    try {
      final was = cleared;
      _status = (await _api.getVerificationStatus()).data;
      // The server widens the account's screens at Level 1 and narrows them
      // again on an expired document; the cached list would deny the new
      // home until the next token refresh.
      if (cleared != was) {
        await _permissions?.load().catchError((Object _) {});
      }
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
