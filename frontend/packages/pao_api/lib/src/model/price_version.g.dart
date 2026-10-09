// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_version.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PriceVersionCWProxy {
  PriceVersion id(String id);

  PriceVersion subServiceId(String subServiceId);

  PriceVersion amount(int amount);

  PriceVersion effectiveFrom(DateTime effectiveFrom);

  PriceVersion createdBy(String createdBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceVersion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceVersion(...).copyWith(id: 12, name: "My name")
  /// ```
  PriceVersion call({
    String id,
    String subServiceId,
    int amount,
    DateTime effectiveFrom,
    String createdBy,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPriceVersion.copyWith(...)` or call `instanceOfPriceVersion.copyWith.fieldName(value)` for a single field.
class _$PriceVersionCWProxyImpl implements _$PriceVersionCWProxy {
  const _$PriceVersionCWProxyImpl(this._value);

  final PriceVersion _value;

  @override
  PriceVersion id(String id) => call(id: id);

  @override
  PriceVersion subServiceId(String subServiceId) =>
      call(subServiceId: subServiceId);

  @override
  PriceVersion amount(int amount) => call(amount: amount);

  @override
  PriceVersion effectiveFrom(DateTime effectiveFrom) =>
      call(effectiveFrom: effectiveFrom);

  @override
  PriceVersion createdBy(String createdBy) => call(createdBy: createdBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceVersion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceVersion(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PriceVersion call({
    Object? id = const $CopyWithPlaceholder(),
    Object? subServiceId = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? effectiveFrom = const $CopyWithPlaceholder(),
    Object? createdBy = const $CopyWithPlaceholder(),
  }) {
    return PriceVersion(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      subServiceId:
          subServiceId == const $CopyWithPlaceholder() || subServiceId == null
          ? _value.subServiceId
          // ignore: cast_nullable_to_non_nullable
          : subServiceId as String,
      amount: amount == const $CopyWithPlaceholder() || amount == null
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      effectiveFrom:
          effectiveFrom == const $CopyWithPlaceholder() || effectiveFrom == null
          ? _value.effectiveFrom
          // ignore: cast_nullable_to_non_nullable
          : effectiveFrom as DateTime,
      createdBy: createdBy == const $CopyWithPlaceholder() || createdBy == null
          ? _value.createdBy
          // ignore: cast_nullable_to_non_nullable
          : createdBy as String,
    );
  }
}

extension $PriceVersionCopyWith on PriceVersion {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPriceVersion.copyWith(...)` or `instanceOfPriceVersion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PriceVersionCWProxy get copyWith => _$PriceVersionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceVersion _$PriceVersionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PriceVersion', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'subServiceId',
          'amount',
          'effectiveFrom',
          'createdBy',
        ],
      );
      final val = PriceVersion(
        id: $checkedConvert('id', (v) => v as String),
        subServiceId: $checkedConvert('subServiceId', (v) => v as String),
        amount: $checkedConvert('amount', (v) => (v as num).toInt()),
        effectiveFrom: $checkedConvert(
          'effectiveFrom',
          (v) => DateTime.parse(v as String),
        ),
        createdBy: $checkedConvert('createdBy', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PriceVersionToJson(PriceVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subServiceId': instance.subServiceId,
      'amount': instance.amount,
      'effectiveFrom': instance.effectiveFrom.toIso8601String(),
      'createdBy': instance.createdBy,
    };
