import 'package:dio/dio.dart';
import 'package:pao_e2e/src/address.dart';

/// A decoded JSON object.
typedef Json = Map<String, Object?>;

/// An authenticated caller; [id] is the account ID.
class ApiSession {
  /// Creates the session.
  const ApiSession({required this.id, required this.token});

  /// Account ID.
  final String id;

  /// Bearer token.
  final String token;
}

/// Thrown when the stack answers with an unexpected status or never reaches
/// the awaited state.
class StackError implements Exception {
  /// Creates the error.
  const StackError(this.message);

  /// What was called and what came back.
  final String message;

  @override
  String toString() => 'StackError: $message';
}

final _sixDigits = RegExp('[0-9]{6}');

/// Plain HTTP to the e2e stack, as the C# API journeys do: no
/// app code, so a journey's setup cannot hide a bug in the app under test.
class StackClient {
  /// Creates the client for the API at [baseUrl]; [dio] is for tests.
  StackClient(String baseUrl, {Dio? dio})
    : http = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    http
      ..options.contentType = Headers.jsonContentType
      ..options.validateStatus = ((_) => true)
      ..interceptors.add(ClientAddress());
  }

  /// The client for the stack `Frontend/test/e2e/run.sh` passes in with
  /// `--dart-define=PAO_API_BASE_URL`, the URL the app under test uses too.
  factory StackClient.fromDefines() =>
      StackClient(const String.fromEnvironment('PAO_API_BASE_URL'));

  /// The underlying client.
  final Dio http;

  /// Calls [path] as [as] and returns the reply, whatever its status.
  Future<Response<Object?>> call(
    String method,
    String path, {
    Object? body,
    ApiSession? as,
  }) => http.request<Object?>(
    path,
    data: body,
    options: Options(
      method: method,
      headers: {if (as != null) 'Authorization': 'Bearer ${as.token}'},
    ),
  );

  /// Calls [path] as [as], failing unless it succeeds; returns the JSON
  /// object replied, or an empty one.
  Future<Json> send(
    String method,
    String path, {
    Object? body,
    ApiSession? as,
  }) async {
    final res = await call(method, path, body: body, as: as);
    final status = res.statusCode ?? 0;
    if (status < 200 || status > 299) {
      throw StackError('$method $path: got $status ${res.data}');
    }
    return switch (res.data) {
      final Json json => json,
      _ => const {},
    };
  }

  /// The session of whoever holds [token], e.g. the app under test's account.
  Future<ApiSession> sessionOf(String token) async {
    final me = await send(
      'GET',
      '/v1/me',
      as: ApiSession(id: '', token: token),
    );
    return ApiSession(id: '${me['id']}', token: token);
  }

  /// The newest one-time code texted to [phone], read from the SMS capture.
  Future<String> lastCode(String phone) async {
    String? code;
    Future<bool> texted() async {
      final sms = await call(
        'GET',
        '/__test/sms?phone=${Uri.encodeQueryComponent(phone)}',
      );
      if (sms.data case {'message': final String text}) {
        code = _sixDigits.firstMatch(text)?.group(0);
      }
      return code != null;
    }

    await eventually(
      'a code texted to $phone',
      texted,
      within: const Duration(seconds: 10),
    );
    return code!;
  }
}

/// Retries [check] every [every] until it passes or [within] runs out; the
/// worker relays events, so effects of an action land shortly after it.
Future<void> eventually(
  String what,
  Future<bool> Function() check, {
  Duration within = const Duration(seconds: 20),
  Duration every = const Duration(milliseconds: 300),
}) async {
  final deadline = DateTime.now().add(within);
  while (!await check()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StackError('timed out waiting for $what');
    }
    await Future<void>.delayed(every);
  }
}
