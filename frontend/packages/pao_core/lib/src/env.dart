/// Build-time configuration passed with `--dart-define`; never holds secrets.
class Env {
  /// Creates an environment description.
  const Env({
    required this.apiBaseUrl,
    required this.flavour,
    this.certificatePins,
  });

  /// Reads the values compiled in with `--dart-define`.
  factory Env.fromDefines() => const Env(
    apiBaseUrl: String.fromEnvironment(
      'PAO_API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
    flavour: String.fromEnvironment('PAO_FLAVOUR', defaultValue: 'dev'),
    certificatePins: String.fromEnvironment('PAO_PIN_SHA256'),
  );

  /// Base URL of the PAO API, without a trailing slash.
  final String apiBaseUrl;

  /// Build flavour: dev, staging or prod.
  final String flavour;

  /// Comma-separated base64 SHA-256 hashes of the API's public keys, pinned by
  /// release builds (`pinningAdapter`). Public-key hashes, not secrets.
  final String? certificatePins;
}
