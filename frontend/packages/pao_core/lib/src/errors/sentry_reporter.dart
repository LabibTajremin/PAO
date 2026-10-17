import 'dart:async';

import 'package:pao_core/src/env.dart';
import 'package:pao_core/src/errors/error_reporter.dart';
import 'package:pao_core/src/errors/scrub.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Starts the SDK; [SentryFlutter.init] in the apps, a fake in tests.
typedef SentryStart = Future<void> Function(
  FlutterOptionsConfiguration configure,
);

/// Sends a captured error; [Sentry.captureException] in the apps.
typedef SentryCapture = Future<SentryId> Function(
  Object error, {
  StackTrace? stackTrace,
});

/// Reports to Sentry through the hub [SentryFlutter.init] set up.
class SentryErrorReporter implements ErrorReporter {
  /// Creates a reporter that sends through [capture].
  SentryErrorReporter({SentryCapture? capture})
    : _capture = capture ?? Sentry.captureException;

  final SentryCapture _capture;

  @override
  Future<void> report(Object error, StackTrace? stack) async {
    await _capture(error, stackTrace: stack);
  }
}

/// Sets the options every PAO app uses: no personal data, no screenshots,
/// no performance tracing, and events scrubbed before they leave the device.
/// Each app has its own Sentry project, so the DSN tells them apart.
void configureSentry(SentryFlutterOptions o, String dsn, Env env) {
  o
    ..dsn = dsn
    ..environment = env.flavour
    ..sendDefaultPii = false
    ..attachScreenshot = false
    ..tracesSampleRate = 0
    // The SDK's own error hooks and installErrorHooks see the same errors;
    // deduplication keeps one event per error.
    ..enableDeduplication = true
    ..beforeSend = scrubEvent
    ..beforeBreadcrumb = scrubBreadcrumb;
}

/// Drops the request and user, and scrubs every message and exception value.
SentryEvent scrubEvent(SentryEvent event, Hint hint) {
  final message = event.message;
  if (message != null) {
    event.message = SentryMessage(scrubPii(message.formatted));
  }
  for (final e in event.exceptions ?? const <SentryException>[]) {
    final value = e.value;
    if (value != null) e.value = scrubPii(value);
  }
  event
    ..request = null
    ..user = null
    ..breadcrumbs = event.breadcrumbs?.map(_scrubCrumb).toList();
  return event;
}

/// Scrubs a breadcrumb before the SDK keeps it.
Breadcrumb? scrubBreadcrumb(Breadcrumb? crumb, Hint hint) =>
    crumb == null ? null : _scrubCrumb(crumb);

Breadcrumb _scrubCrumb(Breadcrumb crumb) {
  final message = crumb.message;
  if (message != null) crumb.message = scrubPii(message);
  crumb.data = crumb.data?.map((k, v) => MapEntry(k, scrubPii('$v')));
  return crumb;
}
