/// Build-time configuration passed with `--dart-define`; never holds secrets.
class Env {
  /// Creates an environment description.
  const Env({required this.apiBaseUrl, required this.flavour});

  /// Reads the values compiled in with `--dart-define`.
  factory Env.fromDefines() => const Env(
    apiBaseUrl: String.fromEnvironment(
      'PAO_API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
    flavour: String.fromEnvironment('PAO_FLAVOUR', defaultValue: 'dev'),
  );

  /// Base URL of the PAO API, without a trailing slash.
  final String apiBaseUrl;

  /// Build flavour: dev, staging or prod.
  final String flavour;
}
