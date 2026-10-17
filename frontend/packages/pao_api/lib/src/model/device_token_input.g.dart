// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_token_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceTokenInputCWProxy {
  DeviceTokenInput token(String token);

  DeviceTokenInput platform(Platform platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceTokenInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceTokenInput(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceTokenInput call({String token, Platform platform});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceTokenInput.copyWith(...)` or call `instanceOfDeviceTokenInput.copyWith.fieldName(value)` for a single field.
class _$DeviceTokenInputCWProxyImpl implements _$DeviceTokenInputCWProxy {
  const _$DeviceTokenInputCWProxyImpl(this._value);

  final DeviceTokenInput _value;

  @override
  DeviceTokenInput token(String token) => call(token: token);

  @override
  DeviceTokenInput platform(Platform platform) => call(platform: platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceTokenInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceTokenInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceTokenInput call({
    Object? token = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
  }) {
    return DeviceTokenInput(
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as Platform,
    );
  }
}

extension $DeviceTokenInputCopyWith on DeviceTokenInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceTokenInput.copyWith(...)` or `instanceOfDeviceTokenInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceTokenInputCWProxy get copyWith => _$DeviceTokenInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceTokenInput _$DeviceTokenInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceTokenInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['token', 'platform']);
      final val = DeviceTokenInput(
        token: $checkedConvert('token', (v) => v as String),
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecode(_$PlatformEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DeviceTokenInputToJson(DeviceTokenInput instance) =>
    <String, dynamic>{
      'token': instance.token,
      'platform': _$PlatformEnumMap[instance.platform]!,
    };

const _$PlatformEnumMap = {
  Platform.android: 'android',
  Platform.ios: 'ios',
  Platform.web: 'web',
};
