// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_proof_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillProofInputCWProxy {
  SkillProofInput mediaIds(List<String> mediaIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillProofInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillProofInput(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillProofInput call({List<String> mediaIds});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillProofInput.copyWith(...)` or call `instanceOfSkillProofInput.copyWith.fieldName(value)` for a single field.
class _$SkillProofInputCWProxyImpl implements _$SkillProofInputCWProxy {
  const _$SkillProofInputCWProxyImpl(this._value);

  final SkillProofInput _value;

  @override
  SkillProofInput mediaIds(List<String> mediaIds) => call(mediaIds: mediaIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillProofInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillProofInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillProofInput call({Object? mediaIds = const $CopyWithPlaceholder()}) {
    return SkillProofInput(
      mediaIds: mediaIds == const $CopyWithPlaceholder() || mediaIds == null
          ? _value.mediaIds
          // ignore: cast_nullable_to_non_nullable
          : mediaIds as List<String>,
    );
  }
}

extension $SkillProofInputCopyWith on SkillProofInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillProofInput.copyWith(...)` or `instanceOfSkillProofInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillProofInputCWProxy get copyWith => _$SkillProofInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillProofInput _$SkillProofInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SkillProofInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['mediaIds']);
      final val = SkillProofInput(
        mediaIds: $checkedConvert(
          'mediaIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SkillProofInputToJson(SkillProofInput instance) =>
    <String, dynamic>{'mediaIds': instance.mediaIds};
