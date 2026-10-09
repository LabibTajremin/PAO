// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level2_session_checklist_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Level2SessionChecklistInnerCWProxy {
  Level2SessionChecklistInner item(String item);

  Level2SessionChecklistInner passed(bool passed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2SessionChecklistInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2SessionChecklistInner(...).copyWith(id: 12, name: "My name")
  /// ```
  Level2SessionChecklistInner call({String item, bool passed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLevel2SessionChecklistInner.copyWith(...)` or call `instanceOfLevel2SessionChecklistInner.copyWith.fieldName(value)` for a single field.
class _$Level2SessionChecklistInnerCWProxyImpl
    implements _$Level2SessionChecklistInnerCWProxy {
  const _$Level2SessionChecklistInnerCWProxyImpl(this._value);

  final Level2SessionChecklistInner _value;

  @override
  Level2SessionChecklistInner item(String item) => call(item: item);

  @override
  Level2SessionChecklistInner passed(bool passed) => call(passed: passed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2SessionChecklistInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2SessionChecklistInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Level2SessionChecklistInner call({
    Object? item = const $CopyWithPlaceholder(),
    Object? passed = const $CopyWithPlaceholder(),
  }) {
    return Level2SessionChecklistInner(
      item: item == const $CopyWithPlaceholder() || item == null
          ? _value.item
          // ignore: cast_nullable_to_non_nullable
          : item as String,
      passed: passed == const $CopyWithPlaceholder() || passed == null
          ? _value.passed
          // ignore: cast_nullable_to_non_nullable
          : passed as bool,
    );
  }
}

extension $Level2SessionChecklistInnerCopyWith on Level2SessionChecklistInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLevel2SessionChecklistInner.copyWith(...)` or `instanceOfLevel2SessionChecklistInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Level2SessionChecklistInnerCWProxy get copyWith =>
      _$Level2SessionChecklistInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level2SessionChecklistInner _$Level2SessionChecklistInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Level2SessionChecklistInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['item', 'passed']);
  final val = Level2SessionChecklistInner(
    item: $checkedConvert('item', (v) => v as String),
    passed: $checkedConvert('passed', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$Level2SessionChecklistInnerToJson(
  Level2SessionChecklistInner instance,
) => <String, dynamic>{'item': instance.item, 'passed': instance.passed};
