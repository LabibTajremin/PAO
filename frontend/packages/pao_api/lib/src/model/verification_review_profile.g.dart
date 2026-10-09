// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_review_profile.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VerificationReviewProfileCWProxy {
  VerificationReviewProfile fullName(String fullName);

  VerificationReviewProfile dateOfBirth(DateTime dateOfBirth);

  VerificationReviewProfile gender(Gender gender);

  VerificationReviewProfile phone(String phone);

  VerificationReviewProfile presentAddress(String? presentAddress);

  VerificationReviewProfile permanentAddress(String? permanentAddress);

  VerificationReviewProfile nidNumber(String? nidNumber);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationReviewProfile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationReviewProfile(...).copyWith(id: 12, name: "My name")
  /// ```
  VerificationReviewProfile call({
    String fullName,
    DateTime dateOfBirth,
    Gender gender,
    String phone,
    String? presentAddress,
    String? permanentAddress,
    String? nidNumber,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVerificationReviewProfile.copyWith(...)` or call `instanceOfVerificationReviewProfile.copyWith.fieldName(value)` for a single field.
class _$VerificationReviewProfileCWProxyImpl
    implements _$VerificationReviewProfileCWProxy {
  const _$VerificationReviewProfileCWProxyImpl(this._value);

  final VerificationReviewProfile _value;

  @override
  VerificationReviewProfile fullName(String fullName) =>
      call(fullName: fullName);

  @override
  VerificationReviewProfile dateOfBirth(DateTime dateOfBirth) =>
      call(dateOfBirth: dateOfBirth);

  @override
  VerificationReviewProfile gender(Gender gender) => call(gender: gender);

  @override
  VerificationReviewProfile phone(String phone) => call(phone: phone);

  @override
  VerificationReviewProfile presentAddress(String? presentAddress) =>
      call(presentAddress: presentAddress);

  @override
  VerificationReviewProfile permanentAddress(String? permanentAddress) =>
      call(permanentAddress: permanentAddress);

  @override
  VerificationReviewProfile nidNumber(String? nidNumber) =>
      call(nidNumber: nidNumber);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationReviewProfile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationReviewProfile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VerificationReviewProfile call({
    Object? fullName = const $CopyWithPlaceholder(),
    Object? dateOfBirth = const $CopyWithPlaceholder(),
    Object? gender = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? presentAddress = const $CopyWithPlaceholder(),
    Object? permanentAddress = const $CopyWithPlaceholder(),
    Object? nidNumber = const $CopyWithPlaceholder(),
  }) {
    return VerificationReviewProfile(
      fullName: fullName == const $CopyWithPlaceholder() || fullName == null
          ? _value.fullName
          // ignore: cast_nullable_to_non_nullable
          : fullName as String,
      dateOfBirth:
          dateOfBirth == const $CopyWithPlaceholder() || dateOfBirth == null
          ? _value.dateOfBirth
          // ignore: cast_nullable_to_non_nullable
          : dateOfBirth as DateTime,
      gender: gender == const $CopyWithPlaceholder() || gender == null
          ? _value.gender
          // ignore: cast_nullable_to_non_nullable
          : gender as Gender,
      phone: phone == const $CopyWithPlaceholder() || phone == null
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      presentAddress: presentAddress == const $CopyWithPlaceholder()
          ? _value.presentAddress
          // ignore: cast_nullable_to_non_nullable
          : presentAddress as String?,
      permanentAddress: permanentAddress == const $CopyWithPlaceholder()
          ? _value.permanentAddress
          // ignore: cast_nullable_to_non_nullable
          : permanentAddress as String?,
      nidNumber: nidNumber == const $CopyWithPlaceholder()
          ? _value.nidNumber
          // ignore: cast_nullable_to_non_nullable
          : nidNumber as String?,
    );
  }
}

extension $VerificationReviewProfileCopyWith on VerificationReviewProfile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVerificationReviewProfile.copyWith(...)` or `instanceOfVerificationReviewProfile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VerificationReviewProfileCWProxy get copyWith =>
      _$VerificationReviewProfileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationReviewProfile _$VerificationReviewProfileFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VerificationReviewProfile', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['fullName', 'dateOfBirth', 'gender', 'phone'],
  );
  final val = VerificationReviewProfile(
    fullName: $checkedConvert('fullName', (v) => v as String),
    dateOfBirth: $checkedConvert(
      'dateOfBirth',
      (v) => DateTime.parse(v as String),
    ),
    gender: $checkedConvert('gender', (v) => $enumDecode(_$GenderEnumMap, v)),
    phone: $checkedConvert('phone', (v) => v as String),
    presentAddress: $checkedConvert('presentAddress', (v) => v as String?),
    permanentAddress: $checkedConvert('permanentAddress', (v) => v as String?),
    nidNumber: $checkedConvert('nidNumber', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$VerificationReviewProfileToJson(
  VerificationReviewProfile instance,
) => <String, dynamic>{
  'fullName': instance.fullName,
  'dateOfBirth': instance.dateOfBirth.toIso8601String(),
  'gender': _$GenderEnumMap[instance.gender]!,
  'phone': instance.phone,
  'presentAddress': ?instance.presentAddress,
  'permanentAddress': ?instance.permanentAddress,
  'nidNumber': ?instance.nidNumber,
};

const _$GenderEnumMap = {
  Gender.female: 'female',
  Gender.male: 'male',
  Gender.other: 'other',
};
