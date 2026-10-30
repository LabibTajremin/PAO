import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class _Recorder implements ErrorReporter {
  final errors = <Object>[];

  @override
  Future<void> report(Object error, StackTrace? stack) async =>
      errors.add(error);
}

class _Dispatcher implements PlatformDispatcher {
  @override
  ErrorCallback? onError;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('scrubPii', () {
    test('hides phone numbers, tokens, codes and long numbers', () {
      const jwt = 'eyJhbGciOiJFZERTQSJ9.eyJzdWIiOiJ4In0.c2ln';
      final out = scrubPii(
        'call +8801712345678 or 01812345678; Authorization: Bearer abc.def; '
        'jwt $jwt; url /v1/x?token=s3cr3t&page=2; {"otp":"123456", '
        '"refreshToken":"r-1"}; nid 1990123456789; booking PAO-1234',
      );
      expect(out, isNot(contains('1712345678')));
      expect(out, isNot(contains('01812345678')));
      expect(out, isNot(contains('abc.def')));
      expect(out, isNot(contains(jwt)));
      expect(out, isNot(contains('s3cr3t')));
      expect(out, isNot(contains('123456')));
      expect(out, isNot(contains('r-1')));
      expect(out, isNot(contains('1990123456789')));
      expect(out, contains('[phone]'));
      expect(out, contains('page=2'));
      expect(out, contains('PAO-1234'));
    });
  });

  group('installErrorHooks', () {
    test('reports framework and platform errors and keeps old handlers', () {
      final saved = FlutterError.onError;
      addTearDown(() => FlutterError.onError = saved);
      final dispatcher = _Dispatcher();
      final seen = <String>[];
      FlutterError.onError = (d) => seen.add('flutter ${d.exception}');
      final r = _Recorder();
      installErrorHooks(r, dispatcher: dispatcher);
      FlutterError.onError!(FlutterErrorDetails(exception: StateError('a')));
      expect(dispatcher.onError!(StateError('b'), StackTrace.empty), isFalse);
      dispatcher.onError = (_, _) => true;
      installErrorHooks(r, dispatcher: dispatcher);
      expect(dispatcher.onError!(StateError('c'), StackTrace.empty), isTrue);
      expect(seen, ['flutter Bad state: a']);
      expect(r.errors.map((e) => '$e'), [
        'Bad state: a',
        'Bad state: b',
        'Bad state: c',
      ]);
    });
  });

  group('startErrorReporting', () {
    test('stays on the device without a DSN', () async {
      final saved = FlutterError.onError;
      addTearDown(() => FlutterError.onError = saved);
      expect(await startErrorReporting(), isA<NoErrorReporter>());
      await const NoErrorReporter().report(Error(), null);
    });

    test('starts Sentry with private, scrubbed settings', () async {
      final saved = FlutterError.onError;
      addTearDown(() => FlutterError.onError = saved);
      final options = SentryFlutterOptions();
      final reporter = await startErrorReporting(
        dsn: 'https://key@sentry.example/1',
        env: const Env(apiBaseUrl: 'x', flavour: 'staging'),
        start: (configure) async => await configure(options),
      );
      expect(reporter, isA<SentryErrorReporter>());
      expect(options.dsn, 'https://key@sentry.example/1');
      expect(options.environment, 'staging');
      expect(options.sendDefaultPii, isFalse);
      expect(options.beforeSend, isNotNull);
      await reporter.report(StateError('x'), StackTrace.current);
    });

    test('reads the environment from the defines by default', () async {
      final saved = FlutterError.onError;
      addTearDown(() => FlutterError.onError = saved);
      final options = SentryFlutterOptions();
      await startErrorReporting(
        dsn: 'https://key@sentry.example/1',
        start: (configure) async => await configure(options),
      );
      expect(options.environment, 'dev');
    });
  });

  group('SentryErrorReporter', () {
    test('sends the error with its stack', () async {
      final sent = <Object>[];
      final r = SentryErrorReporter(
        capture: (error, {stackTrace}) async {
          sent.add(error);
          return const SentryId.empty();
        },
      );
      await r.report(StateError('x'), null);
      expect(sent, hasLength(1));
    });
  });

  group('scrubEvent', () {
    test('drops the request and user and scrubs text', () {
      final event = SentryEvent(
        message: SentryMessage('login 01712345678 failed'),
        exceptions: [
          SentryException(type: 'E', value: 'token=abc'),
          SentryException(type: 'E', value: null),
        ],
        user: SentryUser(id: 'u1'),
        request: SentryRequest(url: 'https://api/x?otp=1'),
        breadcrumbs: [
          Breadcrumb(message: 'GET /v1/x', data: {'phone': '01712345678'}),
          Breadcrumb(),
        ],
      );
      final out = scrubEvent(event, Hint());
      expect(out.message!.formatted, 'login [phone] failed');
      expect(out.exceptions!.first.value, 'token=[redacted]');
      expect(out.exceptions!.last.value, isNull);
      expect(out.user, isNull);
      expect(out.request, isNull);
      expect(out.breadcrumbs!.first.data, {'phone': '[phone]'});
      expect(scrubEvent(SentryEvent(), Hint()).message, isNull);
    });

    test('scrubs breadcrumbs before they are kept', () {
      final crumb = scrubBreadcrumb(Breadcrumb(message: 'otp: 123456'), Hint());
      expect(crumb!.message, 'otp: [redacted]');
      expect(scrubBreadcrumb(null, Hint()), isNull);
    });
  });
}
