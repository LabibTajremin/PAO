// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_provider_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminProviderListCWProxy {
  AdminProviderList items(List<AdminProviderSummary> items);

  AdminProviderList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminProviderList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminProviderList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminProviderList call({
    List<AdminProviderSummary> items,
    String? nextCursor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminProviderList.copyWith(...)` or call `instanceOfAdminProviderList.copyWith.fieldName(value)` for a single field.
class _$AdminProviderListCWProxyImpl implements _$AdminProviderListCWProxy {
  const _$AdminProviderListCWProxyImpl(this._value);

  final AdminProviderList _value;

  @override
  AdminProviderList items(List<AdminProviderSummary> items) =>
      call(items: items);

  @override
  AdminProviderList nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminProviderList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminProviderList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminProviderList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return AdminProviderList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminProviderSummary>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $AdminProviderListCopyWith on AdminProviderList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminProviderList.copyWith(...)` or `instanceOfAdminProviderList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminProviderListCWProxy get copyWith =>
      _$AdminProviderListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminProviderList _$AdminProviderListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminProviderList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AdminProviderList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AdminProviderSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AdminProviderListToJson(AdminProviderList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
