// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_login_challenge.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminLoginChallengeCWProxy {
  AdminLoginChallenge challengeId(String challengeId);

  AdminLoginChallenge expiresInSeconds(int expiresInSeconds);

  AdminLoginChallenge totpEnrolment(TotpEnrolment? totpEnrolment);

  AdminLoginChallenge mustChangePassword(bool? mustChangePassword);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminLoginChallenge(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminLoginChallenge(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminLoginChallenge call({
    String challengeId,
    int expiresInSeconds,
    TotpEnrolment? totpEnrolment,
    bool? mustChangePassword,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminLoginChallenge.copyWith(...)` or call `instanceOfAdminLoginChallenge.copyWith.fieldName(value)` for a single field.
class _$AdminLoginChallengeCWProxyImpl implements _$AdminLoginChallengeCWProxy {
  const _$AdminLoginChallengeCWProxyImpl(this._value);

  final AdminLoginChallenge _value;

  @override
  AdminLoginChallenge challengeId(String challengeId) =>
      call(challengeId: challengeId);

  @override
  AdminLoginChallenge expiresInSeconds(int expiresInSeconds) =>
      call(expiresInSeconds: expiresInSeconds);

  @override
  AdminLoginChallenge totpEnrolment(TotpEnrolment? totpEnrolment) =>
      call(totpEnrolment: totpEnrolment);

  @override
  AdminLoginChallenge mustChangePassword(bool? mustChangePassword) =>
      call(mustChangePassword: mustChangePassword);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminLoginChallenge(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminLoginChallenge(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminLoginChallenge call({
    Object? challengeId = const $CopyWithPlaceholder(),
    Object? expiresInSeconds = const $CopyWithPlaceholder(),
    Object? totpEnrolment = const $CopyWithPlaceholder(),
    Object? mustChangePassword = const $CopyWithPlaceholder(),
  }) {
    return AdminLoginChallenge(
      challengeId:
          challengeId == const $CopyWithPlaceholder() || challengeId == null
          ? _value.challengeId
          // ignore: cast_nullable_to_non_nullable
          : challengeId as String,
      expiresInSeconds:
          expiresInSeconds == const $CopyWithPlaceholder() ||
              expiresInSeconds == null
          ? _value.expiresInSeconds
          // ignore: cast_nullable_to_non_nullable
          : expiresInSeconds as int,
      totpEnrolment: totpEnrolment == const $CopyWithPlaceholder()
          ? _value.totpEnrolment
          // ignore: cast_nullable_to_non_nullable
          : totpEnrolment as TotpEnrolment?,
      mustChangePassword: mustChangePassword == const $CopyWithPlaceholder()
          ? _value.mustChangePassword
          // ignore: cast_nullable_to_non_nullable
          : mustChangePassword as bool?,
    );
  }
}

extension $AdminLoginChallengeCopyWith on AdminLoginChallenge {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminLoginChallenge.copyWith(...)` or `instanceOfAdminLoginChallenge.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminLoginChallengeCWProxy get copyWith =>
      _$AdminLoginChallengeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoginChallenge _$AdminLoginChallengeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminLoginChallenge', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['challengeId', 'expiresInSeconds']);
      final val = AdminLoginChallenge(
        challengeId: $checkedConvert('challengeId', (v) => v as String),
        expiresInSeconds: $checkedConvert(
          'expiresInSeconds',
          (v) => (v as num).toInt(),
        ),
        totpEnrolment: $checkedConvert(
          'totpEnrolment',
          (v) => v == null
              ? null
              : TotpEnrolment.fromJson(v as Map<String, dynamic>),
        ),
        mustChangePassword: $checkedConvert(
          'mustChangePassword',
          (v) => v as bool?,
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminLoginChallengeToJson(
  AdminLoginChallenge instance,
) => <String, dynamic>{
  'challengeId': instance.challengeId,
  'expiresInSeconds': instance.expiresInSeconds,
  'totpEnrolment': ?instance.totpEnrolment?.toJson(),
  'mustChangePassword': ?instance.mustChangePassword,
};
