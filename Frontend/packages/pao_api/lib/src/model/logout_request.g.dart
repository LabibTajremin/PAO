// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logout_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LogoutRequestCWProxy {
  LogoutRequest allDevices(bool? allDevices);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LogoutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LogoutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  LogoutRequest call({bool? allDevices});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLogoutRequest.copyWith(...)` or call `instanceOfLogoutRequest.copyWith.fieldName(value)` for a single field.
class _$LogoutRequestCWProxyImpl implements _$LogoutRequestCWProxy {
  const _$LogoutRequestCWProxyImpl(this._value);

  final LogoutRequest _value;

  @override
  LogoutRequest allDevices(bool? allDevices) => call(allDevices: allDevices);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LogoutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LogoutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LogoutRequest call({Object? allDevices = const $CopyWithPlaceholder()}) {
    return LogoutRequest(
      allDevices: allDevices == const $CopyWithPlaceholder()
          ? _value.allDevices
          // ignore: cast_nullable_to_non_nullable
          : allDevices as bool?,
    );
  }
}

extension $LogoutRequestCopyWith on LogoutRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLogoutRequest.copyWith(...)` or `instanceOfLogoutRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LogoutRequestCWProxy get copyWith => _$LogoutRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogoutRequest _$LogoutRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LogoutRequest', json, ($checkedConvert) {
      final val = LogoutRequest(
        allDevices: $checkedConvert('allDevices', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$LogoutRequestToJson(LogoutRequest instance) =>
    <String, dynamic>{'allDevices': ?instance.allDevices};
