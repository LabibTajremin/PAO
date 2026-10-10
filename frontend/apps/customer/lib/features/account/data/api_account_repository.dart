import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/account/domain/account_repository.dart';

/// [AddressesRepository] on the PAO API.
class ApiAddressesRepository implements AddressesRepository {
  /// Creates the repository.
  ApiAddressesRepository(Dio api) : _api = CustomerApi(api);

  final CustomerApi _api;

  @override
  Future<List<Address>> list() async =>
      (await _api.listAddresses()).data!.items;

  @override
  Future<void> makeDefault(String id) => _api.setDefaultAddress(addressId: id);

  @override
  Future<void> delete(String id) => _api.deleteAddress(addressId: id);
}

/// [DeleteAccountRepository] on the PAO API.
class ApiDeleteAccountRepository implements DeleteAccountRepository {
  /// Creates the repository.
  ApiDeleteAccountRepository(Dio api) : _me = MeApi(api), _auth = AuthApi(api);

  final MeApi _me;
  final AuthApi _auth;

  @override
  Future<String> requestCode() async {
    final phone = (await _me.getMe()).data!.phone!;
    await _auth.requestOtp(
      otpRequest: OtpRequest(phone: phone, purpose: OtpPurpose.deleteAccount),
    );
    return phone;
  }

  @override
  Future<void> delete(String code) =>
      _me.deleteMe(deleteAccountRequest: DeleteAccountRequest(code: code));
}
