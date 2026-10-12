import 'dart:async';

import 'package:flutter/foundation.dart';

/// Where unexpected errors go. Implementations must never send personal data:
/// phone numbers, tokens and codes are scrubbed before anything leaves the
/// device (see `scrubPii`).
abstract interface class ErrorReporter {
  /// Records [error] with its [stack]; never throws.
  Future<void> report(Object error, StackTrace? stack);
}

/// The default: errors stay on the device (the console in debug builds).
class NoErrorReporter implements ErrorReporter {
  /// Creates a reporter that drops every error.
  const NoErrorReporter();

  @override
  Future<void> report(Object error, StackTrace? stack) async {}
}

/// Sends uncaught framework and platform errors to [reporter]. The handlers
/// that were installed before keep running, so the console in debug builds
/// and the test binding in tests still see every error.
void installErrorHooks(
  ErrorReporter reporter, {
  PlatformDispatcher? dispatcher,
}) {
  final previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    previousFlutter?.call(details);
    unawaited(reporter.report(details.exception, details.stack));
  };
  final platform = dispatcher ?? PlatformDispatcher.instance;
  final previousPlatform = platform.onError;
  platform.onError = (error, stack) {
    unawaited(reporter.report(error, stack));
    return previousPlatform?.call(error, stack) ?? false;
  };
}
