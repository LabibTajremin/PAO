// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_customer_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCustomerListCWProxy {
  AdminCustomerList items(List<AdminCustomerSummary> items);

  AdminCustomerList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCustomerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCustomerList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminCustomerList call({
    List<AdminCustomerSummary> items,
    String? nextCursor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminCustomerList.copyWith(...)` or call `instanceOfAdminCustomerList.copyWith.fieldName(value)` for a single field.
class _$AdminCustomerListCWProxyImpl implements _$AdminCustomerListCWProxy {
  const _$AdminCustomerListCWProxyImpl(this._value);

  final AdminCustomerList _value;

  @override
  AdminCustomerList items(List<AdminCustomerSummary> items) =>
      call(items: items);

  @override
  AdminCustomerList nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCustomerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCustomerList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminCustomerList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return AdminCustomerList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminCustomerSummary>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $AdminCustomerListCopyWith on AdminCustomerList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminCustomerList.copyWith(...)` or `instanceOfAdminCustomerList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCustomerListCWProxy get copyWith =>
      _$AdminCustomerListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCustomerList _$AdminCustomerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminCustomerList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AdminCustomerList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AdminCustomerSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AdminCustomerListToJson(AdminCustomerList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
