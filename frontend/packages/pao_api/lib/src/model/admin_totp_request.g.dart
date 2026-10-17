// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_totp_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminTotpRequestCWProxy {
  AdminTotpRequest challengeId(String challengeId);

  AdminTotpRequest code(String code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminTotpRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminTotpRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminTotpRequest call({String challengeId, String code});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminTotpRequest.copyWith(...)` or call `instanceOfAdminTotpRequest.copyWith.fieldName(value)` for a single field.
class _$AdminTotpRequestCWProxyImpl implements _$AdminTotpRequestCWProxy {
  const _$AdminTotpRequestCWProxyImpl(this._value);

  final AdminTotpRequest _value;

  @override
  AdminTotpRequest challengeId(String challengeId) =>
      call(challengeId: challengeId);

  @override
  AdminTotpRequest code(String code) => call(code: code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminTotpRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminTotpRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminTotpRequest call({
    Object? challengeId = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
  }) {
    return AdminTotpRequest(
      challengeId:
          challengeId == const $CopyWithPlaceholder() || challengeId == null
          ? _value.challengeId
          // ignore: cast_nullable_to_non_nullable
          : challengeId as String,
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $AdminTotpRequestCopyWith on AdminTotpRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminTotpRequest.copyWith(...)` or `instanceOfAdminTotpRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminTotpRequestCWProxy get copyWith => _$AdminTotpRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminTotpRequest _$AdminTotpRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminTotpRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['challengeId', 'code']);
      final val = AdminTotpRequest(
        challengeId: $checkedConvert('challengeId', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AdminTotpRequestToJson(AdminTotpRequest instance) =>
    <String, dynamic>{
      'challengeId': instance.challengeId,
      'code': instance.code,
    };
