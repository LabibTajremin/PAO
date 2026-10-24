// Prepares the admin journey, which runs in a browser that can neither read
// the stack's SMS capture nor write out/e2e/.admins.env: a provider enrolled
// and submitted over HTTP, waiting in the verification queue, and the
// verifier's authenticator key enrolled and saved for the next journeys.
// Prints `PAO_E2E_PROVIDER_ID=…`, `PAO_E2E_PROVIDER_NAME=…` and
// `PAO_E2E_VERIFIER_SECRET=…` for `--dart-define`.
//
// Usage: dart run pao_e2e:submitted_provider out/e2e/.stack.env
import 'dart:io';

import 'package:pao_e2e/secrets_file.dart';
import 'package:pao_e2e/stack.dart';

const _verifier = 'verifier@pao.bd';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('usage: submitted_provider <path to .stack.env>');
    exitCode = 64;
    return;
  }
  final env = readEnvFile(args.single);
  final stack = StackClient(env['PAO_E2E_API']!);
  final secrets = FileSecrets('${File(args.single).parent.path}/.admins.env');
  // Enrolling consumes a code, so it happens only when no journey has yet.
  if (await secrets.read(_verifier) == null) {
    await AdminDriver(
      stack,
      password: env['PAO_E2E_ADMIN_PASSWORD']!,
      secrets: secrets,
    ).signIn(_verifier);
  }
  final partner = PartnerDriver(stack);
  final phone = uniquePhone('016');
  final name = 'Selim ${phone.substring(5)}';
  final session = await partner.signIn(phone);
  await partner.enrol(
    session,
    Enrolment(phone: phone, serviceName: 'Plumber', fullName: name),
  );
  await partner.awaitReview(session);
  stdout
    ..writeln('PAO_E2E_PROVIDER_ID=${session.id}')
    ..writeln('PAO_E2E_PROVIDER_NAME=$name')
    ..writeln('PAO_E2E_VERIFIER_SECRET=${await secrets.read(_verifier)}');
}
