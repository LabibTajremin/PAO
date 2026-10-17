import 'package:dio/dio.dart';
import 'package:pao_admin/features/auth/domain/admin_auth_repository.dart';
import 'package:pao_api/pao_api.dart';

/// [AdminAuthRepository] on the PAO API.
class ApiAdminAuthRepository implements AdminAuthRepository {
  /// Creates the repository.
  ApiAdminAuthRepository(Dio api) : _api = AuthApi(api);

  final AuthApi _api;

  @override
  Future<LoginChallenge> login(String email, String password) async {
    final res = await _api.adminLogin(
      adminLoginRequest: AdminLoginRequest(
        email: email.trim(),
        password: password,
      ),
    );
    final c = res.data!;
    return LoginChallenge(
      id: c.challengeId,
      enrolSecret: c.totpEnrolment?.secret,
      enrolUrl: c.totpEnrolment?.otpauthUrl,
      mustChangePassword: c.mustChangePassword ?? false,
    );
  }

  @override
  Future<String> verify(String challengeId, String code) async {
    final res = await _api.adminVerifyTotp(
      adminTotpRequest: AdminTotpRequest(challengeId: challengeId, code: code),
    );
    return res.data!.accessToken;
  }

  @override
  Future<void> changePassword(String current, String next) =>
      _api.changeAdminPassword(
        adminPasswordChange: AdminPasswordChange(
          currentPassword: current,
          newPassword: next,
        ),
      );
}
