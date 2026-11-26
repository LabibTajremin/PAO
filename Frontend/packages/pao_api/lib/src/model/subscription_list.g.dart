// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubscriptionListCWProxy {
  SubscriptionList items(List<Subscription> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubscriptionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubscriptionList(...).copyWith(id: 12, name: "My name")
  /// ```
  SubscriptionList call({List<Subscription> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubscriptionList.copyWith(...)` or call `instanceOfSubscriptionList.copyWith.fieldName(value)` for a single field.
class _$SubscriptionListCWProxyImpl implements _$SubscriptionListCWProxy {
  const _$SubscriptionListCWProxyImpl(this._value);

  final SubscriptionList _value;

  @override
  SubscriptionList items(List<Subscription> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubscriptionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubscriptionList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SubscriptionList call({Object? items = const $CopyWithPlaceholder()}) {
    return SubscriptionList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Subscription>,
    );
  }
}

extension $SubscriptionListCopyWith on SubscriptionList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubscriptionList.copyWith(...)` or `instanceOfSubscriptionList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubscriptionListCWProxy get copyWith => _$SubscriptionListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionList _$SubscriptionListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubscriptionList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = SubscriptionList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SubscriptionListToJson(SubscriptionList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
