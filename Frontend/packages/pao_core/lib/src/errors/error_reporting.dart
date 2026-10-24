import 'package:pao_core/src/env.dart';
import 'package:pao_core/src/errors/error_reporter.dart';
import 'package:pao_core/src/errors/sentry_reporter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Starts error reporting and hooks the framework and platform
/// error handlers. Sentry is used only when the build sets
/// `--dart-define=PAO_SENTRY_DSN=…`; otherwise errors stay on the device.
Future<ErrorReporter> startErrorReporting({
  Env? env,
  String dsn = const String.fromEnvironment('PAO_SENTRY_DSN'),
  SentryStart? start,
}) async {
  ErrorReporter reporter = const NoErrorReporter();
  if (dsn.isNotEmpty) {
    final config = env ?? Env.fromDefines();
    await (start ?? SentryFlutter.init)((o) => configureSentry(o, dsn, config));
    reporter = SentryErrorReporter();
  }
  installErrorHooks(reporter);
  return reporter;
}
