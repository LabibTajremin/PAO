// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_info_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PersonalInfoInputCWProxy {
  PersonalInfoInput fullName(String fullName);

  PersonalInfoInput dateOfBirth(String dateOfBirth);

  PersonalInfoInput gender(Gender gender);

  PersonalInfoInput presentAddress(String presentAddress);

  PersonalInfoInput permanentAddress(String permanentAddress);

  PersonalInfoInput bio(String? bio);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PersonalInfoInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PersonalInfoInput(...).copyWith(id: 12, name: "My name")
  /// ```
  PersonalInfoInput call({
    String fullName,
    String dateOfBirth,
    Gender gender,
    String presentAddress,
    String permanentAddress,
    String? bio,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPersonalInfoInput.copyWith(...)` or call `instanceOfPersonalInfoInput.copyWith.fieldName(value)` for a single field.
class _$PersonalInfoInputCWProxyImpl implements _$PersonalInfoInputCWProxy {
  const _$PersonalInfoInputCWProxyImpl(this._value);

  final PersonalInfoInput _value;

  @override
  PersonalInfoInput fullName(String fullName) => call(fullName: fullName);

  @override
  PersonalInfoInput dateOfBirth(String dateOfBirth) =>
      call(dateOfBirth: dateOfBirth);

  @override
  PersonalInfoInput gender(Gender gender) => call(gender: gender);

  @override
  PersonalInfoInput presentAddress(String presentAddress) =>
      call(presentAddress: presentAddress);

  @override
  PersonalInfoInput permanentAddress(String permanentAddress) =>
      call(permanentAddress: permanentAddress);

  @override
  PersonalInfoInput bio(String? bio) => call(bio: bio);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PersonalInfoInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PersonalInfoInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PersonalInfoInput call({
    Object? fullName = const $CopyWithPlaceholder(),
    Object? dateOfBirth = const $CopyWithPlaceholder(),
    Object? gender = const $CopyWithPlaceholder(),
    Object? presentAddress = const $CopyWithPlaceholder(),
    Object? permanentAddress = const $CopyWithPlaceholder(),
    Object? bio = const $CopyWithPlaceholder(),
  }) {
    return PersonalInfoInput(
      fullName: fullName == const $CopyWithPlaceholder() || fullName == null
          ? _value.fullName
          // ignore: cast_nullable_to_non_nullable
          : fullName as String,
      dateOfBirth:
          dateOfBirth == const $CopyWithPlaceholder() || dateOfBirth == null
          ? _value.dateOfBirth
          // ignore: cast_nullable_to_non_nullable
          : dateOfBirth as String,
      gender: gender == const $CopyWithPlaceholder() || gender == null
          ? _value.gender
          // ignore: cast_nullable_to_non_nullable
          : gender as Gender,
      presentAddress:
          presentAddress == const $CopyWithPlaceholder() ||
              presentAddress == null
          ? _value.presentAddress
          // ignore: cast_nullable_to_non_nullable
          : presentAddress as String,
      permanentAddress:
          permanentAddress == const $CopyWithPlaceholder() ||
              permanentAddress == null
          ? _value.permanentAddress
          // ignore: cast_nullable_to_non_nullable
          : permanentAddress as String,
      bio: bio == const $CopyWithPlaceholder()
          ? _value.bio
          // ignore: cast_nullable_to_non_nullable
          : bio as String?,
    );
  }
}

extension $PersonalInfoInputCopyWith on PersonalInfoInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPersonalInfoInput.copyWith(...)` or `instanceOfPersonalInfoInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PersonalInfoInputCWProxy get copyWith =>
      _$PersonalInfoInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalInfoInput _$PersonalInfoInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PersonalInfoInput', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'fullName',
      'dateOfBirth',
      'gender',
      'presentAddress',
      'permanentAddress',
    ],
  );
  final val = PersonalInfoInput(
    fullName: $checkedConvert('fullName', (v) => v as String),
    dateOfBirth: $checkedConvert('dateOfBirth', (v) => v as String),
    gender: $checkedConvert('gender', (v) => $enumDecode(_$GenderEnumMap, v)),
    presentAddress: $checkedConvert('presentAddress', (v) => v as String),
    permanentAddress: $checkedConvert('permanentAddress', (v) => v as String),
    bio: $checkedConvert('bio', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$PersonalInfoInputToJson(PersonalInfoInput instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'dateOfBirth': instance.dateOfBirth,
      'gender': _$GenderEnumMap[instance.gender]!,
      'presentAddress': instance.presentAddress,
      'permanentAddress': instance.permanentAddress,
      'bio': ?instance.bio,
    };

const _$GenderEnumMap = {
  Gender.female: 'female',
  Gender.male: 'male',
  Gender.other: 'other',
};
