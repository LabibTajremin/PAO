// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServiceInputCWProxy {
  ServiceInput categoryId(String categoryId);

  ServiceInput name(LocalizedText name);

  ServiceInput iconKey(String iconKey);

  ServiceInput serviceModel(ServiceModel serviceModel);

  ServiceInput requiredLevel(int requiredLevel);

  ServiceInput searchRadiusM(int searchRadiusM);

  ServiceInput womenProvidersOnly(bool? womenProvidersOnly);

  ServiceInput requiresLevel2(bool? requiresLevel2);

  ServiceInput level2Checklist(List<LocalizedText>? level2Checklist);

  ServiceInput published(bool? published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ServiceInput call({
    String categoryId,
    LocalizedText name,
    String iconKey,
    ServiceModel serviceModel,
    int requiredLevel,
    int searchRadiusM,
    bool? womenProvidersOnly,
    bool? requiresLevel2,
    List<LocalizedText>? level2Checklist,
    bool? published,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServiceInput.copyWith(...)` or call `instanceOfServiceInput.copyWith.fieldName(value)` for a single field.
class _$ServiceInputCWProxyImpl implements _$ServiceInputCWProxy {
  const _$ServiceInputCWProxyImpl(this._value);

  final ServiceInput _value;

  @override
  ServiceInput categoryId(String categoryId) => call(categoryId: categoryId);

  @override
  ServiceInput name(LocalizedText name) => call(name: name);

  @override
  ServiceInput iconKey(String iconKey) => call(iconKey: iconKey);

  @override
  ServiceInput serviceModel(ServiceModel serviceModel) =>
      call(serviceModel: serviceModel);

  @override
  ServiceInput requiredLevel(int requiredLevel) =>
      call(requiredLevel: requiredLevel);

  @override
  ServiceInput searchRadiusM(int searchRadiusM) =>
      call(searchRadiusM: searchRadiusM);

  @override
  ServiceInput womenProvidersOnly(bool? womenProvidersOnly) =>
      call(womenProvidersOnly: womenProvidersOnly);

  @override
  ServiceInput requiresLevel2(bool? requiresLevel2) =>
      call(requiresLevel2: requiresLevel2);

  @override
  ServiceInput level2Checklist(List<LocalizedText>? level2Checklist) =>
      call(level2Checklist: level2Checklist);

  @override
  ServiceInput published(bool? published) => call(published: published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServiceInput call({
    Object? categoryId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? iconKey = const $CopyWithPlaceholder(),
    Object? serviceModel = const $CopyWithPlaceholder(),
    Object? requiredLevel = const $CopyWithPlaceholder(),
    Object? searchRadiusM = const $CopyWithPlaceholder(),
    Object? womenProvidersOnly = const $CopyWithPlaceholder(),
    Object? requiresLevel2 = const $CopyWithPlaceholder(),
    Object? level2Checklist = const $CopyWithPlaceholder(),
    Object? published = const $CopyWithPlaceholder(),
  }) {
    return ServiceInput(
      categoryId:
          categoryId == const $CopyWithPlaceholder() || categoryId == null
          ? _value.categoryId
          // ignore: cast_nullable_to_non_nullable
          : categoryId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as LocalizedText,
      iconKey: iconKey == const $CopyWithPlaceholder() || iconKey == null
          ? _value.iconKey
          // ignore: cast_nullable_to_non_nullable
          : iconKey as String,
      serviceModel:
          serviceModel == const $CopyWithPlaceholder() || serviceModel == null
          ? _value.serviceModel
          // ignore: cast_nullable_to_non_nullable
          : serviceModel as ServiceModel,
      requiredLevel:
          requiredLevel == const $CopyWithPlaceholder() || requiredLevel == null
          ? _value.requiredLevel
          // ignore: cast_nullable_to_non_nullable
          : requiredLevel as int,
      searchRadiusM:
          searchRadiusM == const $CopyWithPlaceholder() || searchRadiusM == null
          ? _value.searchRadiusM
          // ignore: cast_nullable_to_non_nullable
          : searchRadiusM as int,
      womenProvidersOnly: womenProvidersOnly == const $CopyWithPlaceholder()
          ? _value.womenProvidersOnly
          // ignore: cast_nullable_to_non_nullable
          : womenProvidersOnly as bool?,
      requiresLevel2: requiresLevel2 == const $CopyWithPlaceholder()
          ? _value.requiresLevel2
          // ignore: cast_nullable_to_non_nullable
          : requiresLevel2 as bool?,
      level2Checklist: level2Checklist == const $CopyWithPlaceholder()
          ? _value.level2Checklist
          // ignore: cast_nullable_to_non_nullable
          : level2Checklist as List<LocalizedText>?,
      published: published == const $CopyWithPlaceholder()
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool?,
    );
  }
}

extension $ServiceInputCopyWith on ServiceInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServiceInput.copyWith(...)` or `instanceOfServiceInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServiceInputCWProxy get copyWith => _$ServiceInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceInput _$ServiceInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ServiceInput', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'categoryId',
      'name',
      'iconKey',
      'serviceModel',
      'requiredLevel',
      'searchRadiusM',
    ],
  );
  final val = ServiceInput(
    categoryId: $checkedConvert('categoryId', (v) => v as String),
    name: $checkedConvert(
      'name',
      (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
    ),
    iconKey: $checkedConvert('iconKey', (v) => v as String),
    serviceModel: $checkedConvert(
      'serviceModel',
      (v) => $enumDecode(_$ServiceModelEnumMap, v),
    ),
    requiredLevel: $checkedConvert('requiredLevel', (v) => (v as num).toInt()),
    searchRadiusM: $checkedConvert('searchRadiusM', (v) => (v as num).toInt()),
    womenProvidersOnly: $checkedConvert(
      'womenProvidersOnly',
      (v) => v as bool?,
    ),
    requiresLevel2: $checkedConvert('requiresLevel2', (v) => v as bool?),
    level2Checklist: $checkedConvert(
      'level2Checklist',
      (v) => (v as List<dynamic>?)
          ?.map((e) => LocalizedText.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    published: $checkedConvert('published', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$ServiceInputToJson(
  ServiceInput instance,
) => <String, dynamic>{
  'categoryId': instance.categoryId,
  'name': instance.name.toJson(),
  'iconKey': instance.iconKey,
  'serviceModel': _$ServiceModelEnumMap[instance.serviceModel]!,
  'requiredLevel': instance.requiredLevel,
  'searchRadiusM': instance.searchRadiusM,
  'womenProvidersOnly': ?instance.womenProvidersOnly,
  'requiresLevel2': ?instance.requiresLevel2,
  'level2Checklist': ?instance.level2Checklist?.map((e) => e.toJson()).toList(),
  'published': ?instance.published,
};

const _$ServiceModelEnumMap = {
  ServiceModel.onDemand: 'on_demand',
  ServiceModel.durationHire: 'duration_hire',
  ServiceModel.listing: 'listing',
  ServiceModel.partnerReferral: 'partner_referral',
};
