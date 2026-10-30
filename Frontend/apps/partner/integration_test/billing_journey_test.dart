import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_e2e/secrets_file.dart';
import 'package:pao_partner/app/app.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/job/presentation/live_job_page.dart';

import 'support/billing_stack.dart';
import 'support/stack_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a blocked merchant pays the due, an admin confirms it and the '
      'merchant accepts again', (tester) async {
    final stack = StackClient.fromDefines();
    final admins = stackAdmins(stack);
    final billing = BillingAdmin(stack, admins);
    final phone = uniquePhone('018', 9);
    final partner = PartnerDriver(stack);
    final merchant = await partner.signIn(phone);
    await partner.enrol(
      merchant,
      Enrolment(phone: phone, serviceName: 'Electrician', fullName: 'Kamal'),
    );
    await admins.approve(merchant.id);
    await partner.goOnline(merchant);
    final jobs = JobDriver(stack, merchant);
    final customer = await CustomerBooker.create(stack, uniquePhone('017', 9));

    // A zero limit blocks any due, so one completed job is enough; it is put
    // back for the journeys that follow.
    final limit = await billing.setDueLimit('0');
    try {
      final done = await customer.book(merchant.id);
      for (final step in ['accept', 'on-the-way', 'arrived']) {
        await jobs.mark(done, step);
      }
      await jobs.start(done, await customer.startCode(done));
      await jobs.complete(done);
      final next = await customer.book(merchant.id);
      // The commission is charged from the completion event, a moment later.
      await eventually(
        'the commission was charged',
        () async => await _due(stack, merchant) > 0,
      );
      final due = await _due(stack, merchant);

      final services = await stackServices();
      await services.sessions.signIn(Session(accessToken: merchant.token));
      await services.permissions.load();
      await services.gate.load();
      await tester.pumpWidget(
        PaoApp(services: services, initial: Routes.requestOf(next)),
      );
      await tapText(tester, 'Accept');
      await pumpUntil(tester, find.textContaining('Pay to accept new jobs'));

      await tapText(tester, 'Pay now');
      await typeInto(tester, 'Amount (৳)', (due / 100).toStringAsFixed(2));
      await tapText(tester, 'bKash');
      await typeInto(tester, 'Reference', 'TX-${phone.substring(5)}');
      await tapText(tester, 'Submit payment');
      await pumpUntil(tester, find.text('Accept'));

      await billing.confirmPayment(merchant.id);
      await eventually(
        'the due cleared',
        () async => await _due(stack, merchant) == 0,
      );
      await tapText(tester, 'Accept');
      await pumpUntil(tester, find.byType(LiveJobPage));
    } finally {
      await billing.setDueLimit(limit);
    }
  });
}

Future<int> _due(StackClient stack, ApiSession merchant) async =>
    (await stack.send(
          'GET',
          '/v1/provider/billing/summary',
          as: merchant,
        ))['due']!
        as int;
