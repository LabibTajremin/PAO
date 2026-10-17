import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pao_api/pao_api.dart';

/// The sign-up gate (C-01): a new account has no customer profile, and until
/// it saves one only the profile and location set-up screens are open.
class ProfileGate extends ChangeNotifier {
  /// Creates the gate reading through [api].
  ProfileGate(Dio api) : _api = CustomerApi(api);

  final CustomerApi _api;
  CustomerProfile? _profile;
  bool _missing = false;

  /// The last loaded profile.
  CustomerProfile? get profile => _profile;

  /// Whether the account has no profile yet.
  bool get missing => _missing;

  /// Reloads the profile; a failure other than "not found" keeps the last
  /// answer so being offline never locks the customer out.
  Future<void> load() async {
    try {
      _profile = (await _api.getCustomerProfile()).data;
      _missing = false;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) return;
      _profile = null;
      _missing = true;
    }
    notifyListeners();
  }

  /// Records a profile just saved.
  void saved(CustomerProfile profile) {
    _profile = profile;
    _missing = false;
    notifyListeners();
  }

  /// Forgets the profile, e.g. on sign-out.
  void clear() {
    _profile = null;
    _missing = false;
    notifyListeners();
  }
}
