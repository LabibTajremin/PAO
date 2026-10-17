// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServiceCWProxy {
  Service id(String id);

  Service categoryId(String categoryId);

  Service name(LocalizedText name);

  Service iconKey(String iconKey);

  Service serviceModel(ServiceModel serviceModel);

  Service requiredLevel(int requiredLevel);

  Service searchRadiusM(int searchRadiusM);

  Service womenProvidersOnly(bool womenProvidersOnly);

  Service requiresLevel2(bool requiresLevel2);

  Service level2Checklist(List<LocalizedText>? level2Checklist);

  Service published(bool published);

  Service subServices(List<SubService>? subServices);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Service(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Service(...).copyWith(id: 12, name: "My name")
  /// ```
  Service call({
    String id,
    String categoryId,
    LocalizedText name,
    String iconKey,
    ServiceModel serviceModel,
    int requiredLevel,
    int searchRadiusM,
    bool womenProvidersOnly,
    bool requiresLevel2,
    List<LocalizedText>? level2Checklist,
    bool published,
    List<SubService>? subServices,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfService.copyWith(...)` or call `instanceOfService.copyWith.fieldName(value)` for a single field.
class _$ServiceCWProxyImpl implements _$ServiceCWProxy {
  const _$ServiceCWProxyImpl(this._value);

  final Service _value;

  @override
  Service id(String id) => call(id: id);

  @override
  Service categoryId(String categoryId) => call(categoryId: categoryId);

  @override
  Service name(LocalizedText name) => call(name: name);

  @override
  Service iconKey(String iconKey) => call(iconKey: iconKey);

  @override
  Service serviceModel(ServiceModel serviceModel) =>
      call(serviceModel: serviceModel);

  @override
  Service requiredLevel(int requiredLevel) =>
      call(requiredLevel: requiredLevel);

  @override
  Service searchRadiusM(int searchRadiusM) =>
      call(searchRadiusM: searchRadiusM);

  @override
  Service womenProvidersOnly(bool womenProvidersOnly) =>
      call(womenProvidersOnly: womenProvidersOnly);

  @override
  Service requiresLevel2(bool requiresLevel2) =>
      call(requiresLevel2: requiresLevel2);

  @override
  Service level2Checklist(List<LocalizedText>? level2Checklist) =>
      call(level2Checklist: level2Checklist);

  @override
  Service published(bool published) => call(published: published);

  @override
  Service subServices(List<SubService>? subServices) =>
      call(subServices: subServices);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Service(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Service(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Service call({
    Object? id = const $CopyWithPlaceholder(),
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
    Object? subServices = const $CopyWithPlaceholder(),
  }) {
    return Service(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
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
      womenProvidersOnly:
          womenProvidersOnly == const $CopyWithPlaceholder() ||
              womenProvidersOnly == null
          ? _value.womenProvidersOnly
          // ignore: cast_nullable_to_non_nullable
          : womenProvidersOnly as bool,
      requiresLevel2:
          requiresLevel2 == const $CopyWithPlaceholder() ||
              requiresLevel2 == null
          ? _value.requiresLevel2
          // ignore: cast_nullable_to_non_nullable
          : requiresLevel2 as bool,
      level2Checklist: level2Checklist == const $CopyWithPlaceholder()
          ? _value.level2Checklist
          // ignore: cast_nullable_to_non_nullable
          : level2Checklist as List<LocalizedText>?,
      published: published == const $CopyWithPlaceholder() || published == null
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool,
      subServices: subServices == const $CopyWithPlaceholder()
          ? _value.subServices
          // ignore: cast_nullable_to_non_nullable
          : subServices as List<SubService>?,
    );
  }
}

extension $ServiceCopyWith on Service {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfService.copyWith(...)` or `instanceOfService.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServiceCWProxy get copyWith => _$ServiceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Service _$ServiceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Service', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'categoryId',
      'name',
      'iconKey',
      'serviceModel',
      'requiredLevel',
      'searchRadiusM',
      'womenProvidersOnly',
      'requiresLevel2',
      'published',
    ],
  );
  final val = Service(
    id: $checkedConvert('id', (v) => v as String),
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
    womenProvidersOnly: $checkedConvert('womenProvidersOnly', (v) => v as bool),
    requiresLevel2: $checkedConvert('requiresLevel2', (v) => v as bool),
    level2Checklist: $checkedConvert(
      'level2Checklist',
      (v) => (v as List<dynamic>?)
          ?.map((e) => LocalizedText.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    published: $checkedConvert('published', (v) => v as bool),
    subServices: $checkedConvert(
      'subServices',
      (v) => (v as List<dynamic>?)
          ?.map((e) => SubService.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ServiceToJson(Service instance) => <String, dynamic>{
  'id': instance.id,
  'categoryId': instance.categoryId,
  'name': instance.name.toJson(),
  'iconKey': instance.iconKey,
  'serviceModel': _$ServiceModelEnumMap[instance.serviceModel]!,
  'requiredLevel': instance.requiredLevel,
  'searchRadiusM': instance.searchRadiusM,
  'womenProvidersOnly': instance.womenProvidersOnly,
  'requiresLevel2': instance.requiresLevel2,
  'level2Checklist': ?instance.level2Checklist?.map((e) => e.toJson()).toList(),
  'published': instance.published,
  'subServices': ?instance.subServices?.map((e) => e.toJson()).toList(),
};

const _$ServiceModelEnumMap = {
  ServiceModel.onDemand: 'on_demand',
  ServiceModel.durationHire: 'duration_hire',
  ServiceModel.listing: 'listing',
  ServiceModel.partnerReferral: 'partner_referral',
};
