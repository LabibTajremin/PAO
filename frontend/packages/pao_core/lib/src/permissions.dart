import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// What the signed-in account may do and see, from `/v1/me/permissions`. The
/// server enforces the same rules; this only hides what would be refused.
class PermissionService extends ChangeNotifier {
  /// Creates the service reading through the API client.
  PermissionService(this._dio);

  final Dio _dio;
  Set<String> _permissions = const {};
  Set<String> _screens = const {};
  Set<String> _roles = const {};

  /// Roles of the account, e.g. `customer` or `verifier`.
  Set<String> get roles => _roles;

  /// Reloads the lists; call after sign-in and after each token refresh.
  Future<void> load() async {
    final res = await _dio.get<Map<String, Object?>>('/v1/me/permissions');
    final body = res.data!;
    Set<String> read(String key) =>
        (body[key]! as List<Object?>).cast<String>().toSet();
    _roles = read('roles');
    _permissions = read('permissions');
    _screens = read('screens');
    notifyListeners();
  }

  /// Forgets everything, e.g. on sign-out.
  void clear() {
    _roles = _permissions = _screens = const {};
    notifyListeners();
  }

  /// Whether the account holds [permission].
  bool can(String permission) => _permissions.contains(permission);

  /// Whether the account may open screen [screenId] (e.g. `C07`).
  bool canSee(String screenId) => _screens.contains(screenId);
}
