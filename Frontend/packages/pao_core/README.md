# pao_core

Networking, session, permissions and routing shared by every PAO app.

## Error reporting

Each app's `main()` calls `startErrorReporting()` right after
`WidgetsFlutterBinding.ensureInitialized()`. It hooks `FlutterError.onError` and
`PlatformDispatcher.onError` (keeping the handlers that were there before) and sends
uncaught errors to an `ErrorReporter`:

- `NoErrorReporter` (default): nothing leaves the device.
- `SentryErrorReporter`: used only when the build sets
  `--dart-define=PAO_SENTRY_DSN=<dsn>`. Use one Sentry project (and DSN) per app; the
  environment is the `PAO_FLAVOUR`. The DSN is not a secret, but keep it in CI
  variables so forks do not report into PAO's projects.

Nothing personal is sent (PRD §6.6, §11): no default PII, no screenshots, no tracing;
`scrubEvent` drops the request and user and runs `scrubPii` over messages, exception
values and breadcrumbs, replacing phone numbers, bearer tokens, JWTs, `token=`,
`code=`, `otp=` and `password=` values and long digit runs (NID numbers).
Report handled errors worth knowing about through the same interface:
`reporter.report(error, stack)`.
