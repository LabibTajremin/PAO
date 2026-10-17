import 'package:pao_api/pao_api.dart';

/// Most addresses one account may save (API limit).
const maxAddresses = 10;

/// The customer's saved addresses (C24, C-02).
abstract interface class AddressesRepository {
  /// Every saved address.
  Future<List<Address>> list();

  /// Makes [id] the default address.
  Future<void> makeDefault(String id);

  /// Deletes [id].
  Future<void> delete(String id);
}

/// Deleting the account after confirming with a code (PRD §11).
abstract interface class DeleteAccountRepository {
  /// Sends a `delete_account` code to the account's phone and returns that
  /// phone number.
  Future<String> requestCode();

  /// Deletes the account if [code] is right.
  Future<void> delete(String code);
}
