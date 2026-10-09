// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level2_result_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Level2ResultInputCWProxy {
  Level2ResultInput result(Level2Result result);

  Level2ResultInput checklist(List<Level2ResultInputChecklistInner> checklist);

  Level2ResultInput notes(String? notes);

  Level2ResultInput visitLocation(Point? visitLocation);

  Level2ResultInput photoMediaIds(List<String>? photoMediaIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2ResultInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2ResultInput(...).copyWith(id: 12, name: "My name")
  /// ```
  Level2ResultInput call({
    Level2Result result,
    List<Level2ResultInputChecklistInner> checklist,
    String? notes,
    Point? visitLocation,
    List<String>? photoMediaIds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLevel2ResultInput.copyWith(...)` or call `instanceOfLevel2ResultInput.copyWith.fieldName(value)` for a single field.
class _$Level2ResultInputCWProxyImpl implements _$Level2ResultInputCWProxy {
  const _$Level2ResultInputCWProxyImpl(this._value);

  final Level2ResultInput _value;

  @override
  Level2ResultInput result(Level2Result result) => call(result: result);

  @override
  Level2ResultInput checklist(
    List<Level2ResultInputChecklistInner> checklist,
  ) => call(checklist: checklist);

  @override
  Level2ResultInput notes(String? notes) => call(notes: notes);

  @override
  Level2ResultInput visitLocation(Point? visitLocation) =>
      call(visitLocation: visitLocation);

  @override
  Level2ResultInput photoMediaIds(List<String>? photoMediaIds) =>
      call(photoMediaIds: photoMediaIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2ResultInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2ResultInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Level2ResultInput call({
    Object? result = const $CopyWithPlaceholder(),
    Object? checklist = const $CopyWithPlaceholder(),
    Object? notes = const $CopyWithPlaceholder(),
    Object? visitLocation = const $CopyWithPlaceholder(),
    Object? photoMediaIds = const $CopyWithPlaceholder(),
  }) {
    return Level2ResultInput(
      result: result == const $CopyWithPlaceholder() || result == null
          ? _value.result
          // ignore: cast_nullable_to_non_nullable
          : result as Level2Result,
      checklist: checklist == const $CopyWithPlaceholder() || checklist == null
          ? _value.checklist
          // ignore: cast_nullable_to_non_nullable
          : checklist as List<Level2ResultInputChecklistInner>,
      notes: notes == const $CopyWithPlaceholder()
          ? _value.notes
          // ignore: cast_nullable_to_non_nullable
          : notes as String?,
      visitLocation: visitLocation == const $CopyWithPlaceholder()
          ? _value.visitLocation
          // ignore: cast_nullable_to_non_nullable
          : visitLocation as Point?,
      photoMediaIds: photoMediaIds == const $CopyWithPlaceholder()
          ? _value.photoMediaIds
          // ignore: cast_nullable_to_non_nullable
          : photoMediaIds as List<String>?,
    );
  }
}

extension $Level2ResultInputCopyWith on Level2ResultInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLevel2ResultInput.copyWith(...)` or `instanceOfLevel2ResultInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Level2ResultInputCWProxy get copyWith =>
      _$Level2ResultInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level2ResultInput _$Level2ResultInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Level2ResultInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['result', 'checklist']);
      final val = Level2ResultInput(
        result: $checkedConvert(
          'result',
          (v) => $enumDecode(_$Level2ResultEnumMap, v),
        ),
        checklist: $checkedConvert(
          'checklist',
          (v) => (v as List<dynamic>)
              .map(
                (e) => Level2ResultInputChecklistInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        notes: $checkedConvert('notes', (v) => v as String?),
        visitLocation: $checkedConvert(
          'visitLocation',
          (v) => v == null ? null : Point.fromJson(v as Map<String, dynamic>),
        ),
        photoMediaIds: $checkedConvert(
          'photoMediaIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$Level2ResultInputToJson(Level2ResultInput instance) =>
    <String, dynamic>{
      'result': _$Level2ResultEnumMap[instance.result]!,
      'checklist': instance.checklist.map((e) => e.toJson()).toList(),
      'notes': ?instance.notes,
      'visitLocation': ?instance.visitLocation?.toJson(),
      'photoMediaIds': ?instance.photoMediaIds,
    };

const _$Level2ResultEnumMap = {
  Level2Result.pass: 'pass',
  Level2Result.fail: 'fail',
  Level2Result.retest: 'retest',
};
