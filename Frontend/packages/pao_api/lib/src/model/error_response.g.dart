// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ErrorResponseCWProxy {
  ErrorResponse error(ErrorBody error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ErrorResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ErrorResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  ErrorResponse call({ErrorBody error});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfErrorResponse.copyWith(...)` or call `instanceOfErrorResponse.copyWith.fieldName(value)` for a single field.
class _$ErrorResponseCWProxyImpl implements _$ErrorResponseCWProxy {
  const _$ErrorResponseCWProxyImpl(this._value);

  final ErrorResponse _value;

  @override
  ErrorResponse error(ErrorBody error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ErrorResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ErrorResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ErrorResponse call({Object? error = const $CopyWithPlaceholder()}) {
    return ErrorResponse(
      error: error == const $CopyWithPlaceholder() || error == null
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as ErrorBody,
    );
  }
}

extension $ErrorResponseCopyWith on ErrorResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfErrorResponse.copyWith(...)` or `instanceOfErrorResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ErrorResponseCWProxy get copyWith => _$ErrorResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ErrorResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['error']);
      final val = ErrorResponse(
        error: $checkedConvert(
          'error',
          (v) => ErrorBody.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{'error': instance.error.toJson()};
