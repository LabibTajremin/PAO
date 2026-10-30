// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level2_result_input_checklist_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Level2ResultInputChecklistInnerCWProxy {
  Level2ResultInputChecklistInner item(String item);

  Level2ResultInputChecklistInner passed(bool passed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2ResultInputChecklistInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2ResultInputChecklistInner(...).copyWith(id: 12, name: "My name")
  /// ```
  Level2ResultInputChecklistInner call({String item, bool passed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLevel2ResultInputChecklistInner.copyWith(...)` or call `instanceOfLevel2ResultInputChecklistInner.copyWith.fieldName(value)` for a single field.
class _$Level2ResultInputChecklistInnerCWProxyImpl
    implements _$Level2ResultInputChecklistInnerCWProxy {
  const _$Level2ResultInputChecklistInnerCWProxyImpl(this._value);

  final Level2ResultInputChecklistInner _value;

  @override
  Level2ResultInputChecklistInner item(String item) => call(item: item);

  @override
  Level2ResultInputChecklistInner passed(bool passed) => call(passed: passed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2ResultInputChecklistInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2ResultInputChecklistInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Level2ResultInputChecklistInner call({
    Object? item = const $CopyWithPlaceholder(),
    Object? passed = const $CopyWithPlaceholder(),
  }) {
    return Level2ResultInputChecklistInner(
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

extension $Level2ResultInputChecklistInnerCopyWith
    on Level2ResultInputChecklistInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLevel2ResultInputChecklistInner.copyWith(...)` or `instanceOfLevel2ResultInputChecklistInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Level2ResultInputChecklistInnerCWProxy get copyWith =>
      _$Level2ResultInputChecklistInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level2ResultInputChecklistInner _$Level2ResultInputChecklistInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Level2ResultInputChecklistInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['item', 'passed']);
  final val = Level2ResultInputChecklistInner(
    item: $checkedConvert('item', (v) => v as String),
    passed: $checkedConvert('passed', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$Level2ResultInputChecklistInnerToJson(
  Level2ResultInputChecklistInner instance,
) => <String, dynamic>{'item': instance.item, 'passed': instance.passed};
