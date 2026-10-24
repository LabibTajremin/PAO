import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  final req = RequestOptions(path: '/x');

  DioException timeout(DioExceptionType type) =>
      DioException(requestOptions: req, type: type);

  Response<Object?> res(int status, [Object? data]) =>
      Response(requestOptions: req, statusCode: status, data: data);

  test('timeouts and lost links become network failures', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(AppFailure.from(timeout(type)).code, 'TIMEOUT');
    }
    final offline = AppFailure.from(timeout(DioExceptionType.connectionError));
    expect(offline, isA<NetworkFailure>());
    expect(offline.code, 'NETWORK');
    expect((offline as NetworkFailure).timedOut, isFalse);
  });

  test('API errors keep their code, status and details', () {
    final f = AppFailure.from(
      DioException(
        requestOptions: req,
        response: res(422, {
          'error': {
            'code': 'VALIDATION_FAILED',
            'message': 'Invalid request.',
            'details': {'field': 'name'},
          },
        }),
      ),
    );
    expect(f, isA<ApiFailure>());
    f as ApiFailure;
    expect(
      [f.code, f.status, f.details['field']],
      ['VALIDATION_FAILED', 422, 'name'],
    );
    final noDetails = ApiFailure.fromResponse(
      res(404, {
        'error': {'code': 'NOT_FOUND', 'message': 'x'},
      }),
    );
    expect(noDetails.details, isEmpty);
  });

  test('responses without the error format fall back on the status', () {
    expect(ApiFailure.fromResponse(res(502, 'Bad gateway')).code, 'INTERNAL');
    expect(ApiFailure.fromResponse(res(418)).code, 'UNEXPECTED');
    final noStatus = ApiFailure.fromResponse(Response(requestOptions: req));
    expect(noStatus.status, 0);
  });

  test('wrapped failures and anything else', () {
    const expired = SessionExpiredFailure();
    expect(AppFailure.from(expired), same(expired));
    expect(
      AppFailure.from(DioException(requestOptions: req, error: expired)),
      same(expired),
    );
    expect(AppFailure.from(StateError('boom')).code, 'UNEXPECTED');
    expect(
      AppFailure.from(timeout(DioExceptionType.cancel)),
      isA<UnexpectedFailure>(),
    );
  });
}
