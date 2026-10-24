import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/auth/domain/auth_repository.dart';

/// [AuthRepository] on the PAO API, signing in to the customer app.
class ApiAuthRepository implements AuthRepository {
  /// Creates the repository.
  ApiAuthRepository(Dio api) : _api = AuthApi(api);

  final AuthApi _api;

  @override
  Future<CodeSent> requestCode(String phone) async {
    final res = await _api.requestOtp(
      otpRequest: OtpRequest(phone: phone, purpose: OtpPurpose.login),
    );
    return CodeSent(
      resendAfter: Duration(seconds: res.data!.resendAfterSeconds),
    );
  }

  @override
  Future<SignedIn> verify(String phone, String code) async {
    final res = await _api.verifyOtp(
      otpVerifyRequest: OtpVerifyRequest(
        phone: phone,
        code: code,
        app: AppKind.customer,
      ),
    );
    final t = res.data!;
    return SignedIn(accessToken: t.accessToken, refreshToken: t.refreshToken);
  }
}
