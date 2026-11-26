// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_window.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeliveryWindowCWProxy {
  DeliveryWindow start(String start);

  DeliveryWindow end(String end);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeliveryWindow(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeliveryWindow(...).copyWith(id: 12, name: "My name")
  /// ```
  DeliveryWindow call({String start, String end});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeliveryWindow.copyWith(...)` or call `instanceOfDeliveryWindow.copyWith.fieldName(value)` for a single field.
class _$DeliveryWindowCWProxyImpl implements _$DeliveryWindowCWProxy {
  const _$DeliveryWindowCWProxyImpl(this._value);

  final DeliveryWindow _value;

  @override
  DeliveryWindow start(String start) => call(start: start);

  @override
  DeliveryWindow end(String end) => call(end: end);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeliveryWindow(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeliveryWindow(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeliveryWindow call({
    Object? start = const $CopyWithPlaceholder(),
    Object? end = const $CopyWithPlaceholder(),
  }) {
    return DeliveryWindow(
      start: start == const $CopyWithPlaceholder() || start == null
          ? _value.start
          // ignore: cast_nullable_to_non_nullable
          : start as String,
      end: end == const $CopyWithPlaceholder() || end == null
          ? _value.end
          // ignore: cast_nullable_to_non_nullable
          : end as String,
    );
  }
}

extension $DeliveryWindowCopyWith on DeliveryWindow {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeliveryWindow.copyWith(...)` or `instanceOfDeliveryWindow.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeliveryWindowCWProxy get copyWith => _$DeliveryWindowCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryWindow _$DeliveryWindowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeliveryWindow', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['start', 'end']);
      final val = DeliveryWindow(
        start: $checkedConvert('start', (v) => v as String),
        end: $checkedConvert('end', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeliveryWindowToJson(DeliveryWindow instance) =>
    <String, dynamic>{'start': instance.start, 'end': instance.end};
