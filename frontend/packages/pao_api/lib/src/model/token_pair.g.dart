// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_pair.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TokenPairCWProxy {
  TokenPair accessToken(String accessToken);

  TokenPair refreshToken(String? refreshToken);

  TokenPair expiresInSeconds(int expiresInSeconds);

  TokenPair isNewAccount(bool? isNewAccount);

  TokenPair account(Account account);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TokenPair(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TokenPair(...).copyWith(id: 12, name: "My name")
  /// ```
  TokenPair call({
    String accessToken,
    String? refreshToken,
    int expiresInSeconds,
    bool? isNewAccount,
    Account account,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTokenPair.copyWith(...)` or call `instanceOfTokenPair.copyWith.fieldName(value)` for a single field.
class _$TokenPairCWProxyImpl implements _$TokenPairCWProxy {
  const _$TokenPairCWProxyImpl(this._value);

  final TokenPair _value;

  @override
  TokenPair accessToken(String accessToken) => call(accessToken: accessToken);

  @override
  TokenPair refreshToken(String? refreshToken) =>
      call(refreshToken: refreshToken);

  @override
  TokenPair expiresInSeconds(int expiresInSeconds) =>
      call(expiresInSeconds: expiresInSeconds);

  @override
  TokenPair isNewAccount(bool? isNewAccount) =>
      call(isNewAccount: isNewAccount);

  @override
  TokenPair account(Account account) => call(account: account);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TokenPair(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TokenPair(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TokenPair call({
    Object? accessToken = const $CopyWithPlaceholder(),
    Object? refreshToken = const $CopyWithPlaceholder(),
    Object? expiresInSeconds = const $CopyWithPlaceholder(),
    Object? isNewAccount = const $CopyWithPlaceholder(),
    Object? account = const $CopyWithPlaceholder(),
  }) {
    return TokenPair(
      accessToken:
          accessToken == const $CopyWithPlaceholder() || accessToken == null
          ? _value.accessToken
          // ignore: cast_nullable_to_non_nullable
          : accessToken as String,
      refreshToken: refreshToken == const $CopyWithPlaceholder()
          ? _value.refreshToken
          // ignore: cast_nullable_to_non_nullable
          : refreshToken as String?,
      expiresInSeconds:
          expiresInSeconds == const $CopyWithPlaceholder() ||
              expiresInSeconds == null
          ? _value.expiresInSeconds
          // ignore: cast_nullable_to_non_nullable
          : expiresInSeconds as int,
      isNewAccount: isNewAccount == const $CopyWithPlaceholder()
          ? _value.isNewAccount
          // ignore: cast_nullable_to_non_nullable
          : isNewAccount as bool?,
      account: account == const $CopyWithPlaceholder() || account == null
          ? _value.account
          // ignore: cast_nullable_to_non_nullable
          : account as Account,
    );
  }
}

extension $TokenPairCopyWith on TokenPair {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTokenPair.copyWith(...)` or `instanceOfTokenPair.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TokenPairCWProxy get copyWith => _$TokenPairCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenPair _$TokenPairFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TokenPair', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['accessToken', 'expiresInSeconds', 'account'],
      );
      final val = TokenPair(
        accessToken: $checkedConvert('accessToken', (v) => v as String),
        refreshToken: $checkedConvert('refreshToken', (v) => v as String?),
        expiresInSeconds: $checkedConvert(
          'expiresInSeconds',
          (v) => (v as num).toInt(),
        ),
        isNewAccount: $checkedConvert('isNewAccount', (v) => v as bool?),
        account: $checkedConvert(
          'account',
          (v) => Account.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TokenPairToJson(TokenPair instance) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': ?instance.refreshToken,
  'expiresInSeconds': instance.expiresInSeconds,
  'isNewAccount': ?instance.isNewAccount,
  'account': instance.account.toJson(),
};
