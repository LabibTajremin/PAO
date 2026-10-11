/// Authenticator secrets in `test/e2e/.admins.env`, shared with the API
/// journeys and every app journey signing in to the same stack. Uses
/// `dart:io`, so desktop and command-line only.
library;

import 'dart:io';

import 'package:pao_e2e/src/admins.dart';
import 'package:pao_e2e/src/client.dart';

/// [SecretStore] on an `email=secret` file; `stack.sh` removes it with the
/// database the secrets belong to.
class FileSecrets implements SecretStore {
  /// Creates the store over [path].
  FileSecrets(String path) : _file = File(path);

  final File _file;

  @override
  Future<String?> read(String email) async {
    if (!_file.existsSync()) return null;
    String? secret;
    for (final line in await _file.readAsLines()) {
      if (line.startsWith('$email=')) secret = line.substring(email.length + 1);
    }
    return secret;
  }

  @override
  Future<void> write(String email, String secret) =>
      _file.writeAsString('$email=$secret\n', mode: FileMode.append);
}

/// Reads `KEY=value` lines, such as `test/e2e/.stack.env`.
Map<String, String> readEnvFile(String path) => {
  for (final line in File(path).readAsLinesSync())
    if (line.indexOf('=') case final i when i > 0)
      line.substring(0, i): line.substring(i + 1),
};

/// The stack's seeded admins, with the password and secrets file
/// `test/e2e/mobile/run.sh` passes in with `--dart-define`.
AdminDriver stackAdmins(StackClient stack) => AdminDriver(
  stack,
  password: const String.fromEnvironment('PAO_E2E_ADMIN_PASSWORD'),
  secrets: FileSecrets(const String.fromEnvironment('PAO_E2E_ADMINS_FILE')),
);
