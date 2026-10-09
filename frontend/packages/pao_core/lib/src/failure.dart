import 'package:dio/dio.dart';

/// A failure the apps can show: [code] is stable and translated by `pao_l10n`.
sealed class AppFailure implements Exception {
  const AppFailure(this.code);

  /// Maps any error from the network layer to a failure the UI understands.
  factory AppFailure.from(Object error) => switch (error) {
    AppFailure() => error,
    DioException(error: final AppFailure inner) => inner,
    DioException(:final type)
        when type == DioExceptionType.connectionTimeout ||
            type == DioExceptionType.sendTimeout ||
            type == DioExceptionType.receiveTimeout =>
      const NetworkFailure(timedOut: true),
    DioException(type: DioExceptionType.connectionError) =>
      const NetworkFailure(),
    DioException(:final response?) => ApiFailure.fromResponse(response),
    _ => const UnexpectedFailure(),
  };

  /// Stable code, e.g. `NOT_FOUND`, `NETWORK` or one of the API's error codes.
  final String code;
}

/// The API answered with its error format (PRD §9.6).
final class ApiFailure extends AppFailure {
  /// Creates a failure with the API's [code], HTTP [status] and [details].
  const ApiFailure(super.code, {required this.status, this.details = const {}});

  /// Reads `{"error": {"code", "message", "details"}}`, falling back to the
  /// status.
  factory ApiFailure.fromResponse(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    final body = response.data;
    if (body is Map<String, Object?> && body['error'] is Map<String, Object?>) {
      final error = body['error']! as Map<String, Object?>;
      final details = error['details'];
      return ApiFailure(
        error['code']! as String,
        status: status,
        details: details is Map<String, Object?> ? details : const {},
      );
    }
    return ApiFailure(
      status >= 500 ? 'INTERNAL' : 'UNEXPECTED',
      status: status,
    );
  }

  /// HTTP status of the response.
  final int status;

  /// Machine-readable context such as invalid fields.
  final Map<String, Object?> details;
}

/// The device could not reach the API (offline or too slow).
final class NetworkFailure extends AppFailure {
  /// Creates a network failure; [timedOut] tells a slow link from no link.
  const NetworkFailure({this.timedOut = false})
    : super(timedOut ? 'TIMEOUT' : 'NETWORK');

  /// Whether the request started but did not finish in time.
  final bool timedOut;
}

/// The refresh token was rejected; the user must sign in again (C63).
final class SessionExpiredFailure extends AppFailure {
  /// Creates the failure.
  const SessionExpiredFailure() : super('SESSION_EXPIRED');
}

/// Anything the apps cannot explain more precisely.
final class UnexpectedFailure extends AppFailure {
  /// Creates the failure.
  const UnexpectedFailure() : super('UNEXPECTED');
}
