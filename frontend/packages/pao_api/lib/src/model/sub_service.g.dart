// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_service.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubServiceCWProxy {
  SubService id(String id);

  SubService serviceId(String serviceId);

  SubService name(LocalizedText name);

  SubService description(LocalizedText? description);

  SubService inclusions(List<LocalizedText>? inclusions);

  SubService exclusions(List<LocalizedText>? exclusions);

  SubService unit(PriceUnit unit);

  SubService price(int price);

  SubService priceVersionId(String priceVersionId);

  SubService maxQuantity(int? maxQuantity);

  SubService published(bool published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubService(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubService(...).copyWith(id: 12, name: "My name")
  /// ```
  SubService call({
    String id,
    String serviceId,
    LocalizedText name,
    LocalizedText? description,
    List<LocalizedText>? inclusions,
    List<LocalizedText>? exclusions,
    PriceUnit unit,
    int price,
    String priceVersionId,
    int? maxQuantity,
    bool published,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubService.copyWith(...)` or call `instanceOfSubService.copyWith.fieldName(value)` for a single field.
class _$SubServiceCWProxyImpl implements _$SubServiceCWProxy {
  const _$SubServiceCWProxyImpl(this._value);

  final SubService _value;

  @override
  SubService id(String id) => call(id: id);

  @override
  SubService serviceId(String serviceId) => call(serviceId: serviceId);

  @override
  SubService name(LocalizedText name) => call(name: name);

  @override
  SubService description(LocalizedText? description) =>
      call(description: description);

  @override
  SubService inclusions(List<LocalizedText>? inclusions) =>
      call(inclusions: inclusions);

  @override
  SubService exclusions(List<LocalizedText>? exclusions) =>
      call(exclusions: exclusions);

  @override
  SubService unit(PriceUnit unit) => call(unit: unit);

  @override
  SubService price(int price) => call(price: price);

  @override
  SubService priceVersionId(String priceVersionId) =>
      call(priceVersionId: priceVersionId);

  @override
  SubService maxQuantity(int? maxQuantity) => call(maxQuantity: maxQuantity);

  @override
  SubService published(bool published) => call(published: published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubService(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubService(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SubService call({
    Object? id = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? inclusions = const $CopyWithPlaceholder(),
    Object? exclusions = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? price = const $CopyWithPlaceholder(),
    Object? priceVersionId = const $CopyWithPlaceholder(),
    Object? maxQuantity = const $CopyWithPlaceholder(),
    Object? published = const $CopyWithPlaceholder(),
  }) {
    return SubService(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      serviceId: serviceId == const $CopyWithPlaceholder() || serviceId == null
          ? _value.serviceId
          // ignore: cast_nullable_to_non_nullable
          : serviceId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as LocalizedText,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as LocalizedText?,
      inclusions: inclusions == const $CopyWithPlaceholder()
          ? _value.inclusions
          // ignore: cast_nullable_to_non_nullable
          : inclusions as List<LocalizedText>?,
      exclusions: exclusions == const $CopyWithPlaceholder()
          ? _value.exclusions
          // ignore: cast_nullable_to_non_nullable
          : exclusions as List<LocalizedText>?,
      unit: unit == const $CopyWithPlaceholder() || unit == null
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as PriceUnit,
      price: price == const $CopyWithPlaceholder() || price == null
          ? _value.price
          // ignore: cast_nullable_to_non_nullable
          : price as int,
      priceVersionId:
          priceVersionId == const $CopyWithPlaceholder() ||
              priceVersionId == null
          ? _value.priceVersionId
          // ignore: cast_nullable_to_non_nullable
          : priceVersionId as String,
      maxQuantity: maxQuantity == const $CopyWithPlaceholder()
          ? _value.maxQuantity
          // ignore: cast_nullable_to_non_nullable
          : maxQuantity as int?,
      published: published == const $CopyWithPlaceholder() || published == null
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool,
    );
  }
}

extension $SubServiceCopyWith on SubService {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubService.copyWith(...)` or `instanceOfSubService.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubServiceCWProxy get copyWith => _$SubServiceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubService _$SubServiceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SubService', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'serviceId',
      'name',
      'unit',
      'price',
      'priceVersionId',
      'published',
    ],
  );
  final val = SubService(
    id: $checkedConvert('id', (v) => v as String),
    serviceId: $checkedConvert('serviceId', (v) => v as String),
    name: $checkedConvert(
      'name',
      (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
    ),
    description: $checkedConvert(
      'description',
      (v) =>
          v == null ? null : LocalizedText.fromJson(v as Map<String, dynamic>),
    ),
    inclusions: $checkedConvert(
      'inclusions',
      (v) => (v as List<dynamic>?)
          ?.map((e) => LocalizedText.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    exclusions: $checkedConvert(
      'exclusions',
      (v) => (v as List<dynamic>?)
          ?.map((e) => LocalizedText.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    unit: $checkedConvert('unit', (v) => $enumDecode(_$PriceUnitEnumMap, v)),
    price: $checkedConvert('price', (v) => (v as num).toInt()),
    priceVersionId: $checkedConvert('priceVersionId', (v) => v as String),
    maxQuantity: $checkedConvert('maxQuantity', (v) => (v as num?)?.toInt()),
    published: $checkedConvert('published', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$SubServiceToJson(SubService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceId': instance.serviceId,
      'name': instance.name.toJson(),
      'description': ?instance.description?.toJson(),
      'inclusions': ?instance.inclusions?.map((e) => e.toJson()).toList(),
      'exclusions': ?instance.exclusions?.map((e) => e.toJson()).toList(),
      'unit': _$PriceUnitEnumMap[instance.unit]!,
      'price': instance.price,
      'priceVersionId': instance.priceVersionId,
      'maxQuantity': ?instance.maxQuantity,
      'published': instance.published,
    };

const _$PriceUnitEnumMap = {
  PriceUnit.job: 'job',
  PriceUnit.unit: 'unit',
  PriceUnit.hour: 'hour',
  PriceUnit.day: 'day',
};
