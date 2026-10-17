// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_service_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubServiceInputCWProxy {
  SubServiceInput serviceId(String serviceId);

  SubServiceInput name(LocalizedText name);

  SubServiceInput description(LocalizedText? description);

  SubServiceInput inclusions(List<LocalizedText>? inclusions);

  SubServiceInput exclusions(List<LocalizedText>? exclusions);

  SubServiceInput unit(PriceUnit unit);

  SubServiceInput maxQuantity(int? maxQuantity);

  SubServiceInput initialPrice(int? initialPrice);

  SubServiceInput published(bool? published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubServiceInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubServiceInput(...).copyWith(id: 12, name: "My name")
  /// ```
  SubServiceInput call({
    String serviceId,
    LocalizedText name,
    LocalizedText? description,
    List<LocalizedText>? inclusions,
    List<LocalizedText>? exclusions,
    PriceUnit unit,
    int? maxQuantity,
    int? initialPrice,
    bool? published,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubServiceInput.copyWith(...)` or call `instanceOfSubServiceInput.copyWith.fieldName(value)` for a single field.
class _$SubServiceInputCWProxyImpl implements _$SubServiceInputCWProxy {
  const _$SubServiceInputCWProxyImpl(this._value);

  final SubServiceInput _value;

  @override
  SubServiceInput serviceId(String serviceId) => call(serviceId: serviceId);

  @override
  SubServiceInput name(LocalizedText name) => call(name: name);

  @override
  SubServiceInput description(LocalizedText? description) =>
      call(description: description);

  @override
  SubServiceInput inclusions(List<LocalizedText>? inclusions) =>
      call(inclusions: inclusions);

  @override
  SubServiceInput exclusions(List<LocalizedText>? exclusions) =>
      call(exclusions: exclusions);

  @override
  SubServiceInput unit(PriceUnit unit) => call(unit: unit);

  @override
  SubServiceInput maxQuantity(int? maxQuantity) =>
      call(maxQuantity: maxQuantity);

  @override
  SubServiceInput initialPrice(int? initialPrice) =>
      call(initialPrice: initialPrice);

  @override
  SubServiceInput published(bool? published) => call(published: published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubServiceInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubServiceInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SubServiceInput call({
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? inclusions = const $CopyWithPlaceholder(),
    Object? exclusions = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? maxQuantity = const $CopyWithPlaceholder(),
    Object? initialPrice = const $CopyWithPlaceholder(),
    Object? published = const $CopyWithPlaceholder(),
  }) {
    return SubServiceInput(
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
      maxQuantity: maxQuantity == const $CopyWithPlaceholder()
          ? _value.maxQuantity
          // ignore: cast_nullable_to_non_nullable
          : maxQuantity as int?,
      initialPrice: initialPrice == const $CopyWithPlaceholder()
          ? _value.initialPrice
          // ignore: cast_nullable_to_non_nullable
          : initialPrice as int?,
      published: published == const $CopyWithPlaceholder()
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool?,
    );
  }
}

extension $SubServiceInputCopyWith on SubServiceInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubServiceInput.copyWith(...)` or `instanceOfSubServiceInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubServiceInputCWProxy get copyWith => _$SubServiceInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubServiceInput _$SubServiceInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SubServiceInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['serviceId', 'name', 'unit']);
  final val = SubServiceInput(
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
    maxQuantity: $checkedConvert('maxQuantity', (v) => (v as num?)?.toInt()),
    initialPrice: $checkedConvert('initialPrice', (v) => (v as num?)?.toInt()),
    published: $checkedConvert('published', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$SubServiceInputToJson(SubServiceInput instance) =>
    <String, dynamic>{
      'serviceId': instance.serviceId,
      'name': instance.name.toJson(),
      'description': ?instance.description?.toJson(),
      'inclusions': ?instance.inclusions?.map((e) => e.toJson()).toList(),
      'exclusions': ?instance.exclusions?.map((e) => e.toJson()).toList(),
      'unit': _$PriceUnitEnumMap[instance.unit]!,
      'maxQuantity': ?instance.maxQuantity,
      'initialPrice': ?instance.initialPrice,
      'published': ?instance.published,
    };

const _$PriceUnitEnumMap = {
  PriceUnit.job: 'job',
  PriceUnit.unit: 'unit',
  PriceUnit.hour: 'hour',
  PriceUnit.day: 'day',
};
