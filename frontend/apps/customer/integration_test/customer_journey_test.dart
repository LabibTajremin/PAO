import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pao_customer/app/app.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_e2e/secrets_file.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/booking_ui.dart';
import 'support/stack_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final stack = StackClient.fromDefines();
  late JobDriver provider;
  late String name;

  // One verified provider online in Banani serves both journeys; it is set
  // up over HTTP, as test/e2e/api does, so only the customer app is driven.
  setUpAll(() async {
    final phone = uniquePhone('018', 7);
    name = 'Rahim ${phone.substring(5)}';
    final partner = PartnerDriver(stack);
    final session = await partner.signIn(phone);
    await partner.enrol(
      session,
      Enrolment(phone: phone, serviceName: 'Electrician', fullName: name),
    );
    await stackAdmins(stack).approve(session.id);
    await partner.goOnline(session);
    provider = JobDriver(stack, session);
  });

  Future<void> startBooking(WidgetTester tester, int n) async {
    await tester.pumpWidget(PaoApp(services: await stackServices()));
    await signUp(tester, stack, uniquePhone('017', n));
    await chooseService(tester);
    await bookAsap(tester, name);
  }

  testWidgets('a customer cancels an accepted booking before it starts', (
    tester,
  ) async {
    await startBooking(tester, 1);
    final id = await provider.nextRequest();
    await provider.mark(id, 'accept');
    await pumpUntil(tester, find.text('$name accepted your booking'));
    await startCode(tester);

    await tapOn(tester, find.widgetWithText(PaoButton, 'Cancel booking'));
    await tapText(tester, 'I changed my mind');
    await tapOn(tester, find.widgetWithText(PaoButton, 'Cancel booking'));
    await pumpUntil(tester, find.text('Booking cancelled'));
  });

  testWidgets('a customer books, follows the job to completion and rates', (
    tester,
  ) async {
    await startBooking(tester, 2);
    final id = await provider.nextRequest();
    await provider.mark(id, 'accept');
    await pumpUntil(tester, find.text('$name accepted your booking'));
    final code = await startCode(tester);

    await provider.mark(id, 'on-the-way');
    await pumpUntil(tester, find.text('$name is on the way'));
    await provider.mark(id, 'arrived');
    await pumpUntil(tester, find.text('$name has arrived'));
    await provider.start(id, code);
    await pumpUntil(tester, find.text('Job in progress'));
    await provider.complete(id);
    await pumpUntil(tester, find.text('All done!'));

    await tapText(tester, 'Rate $name');
    await tapOn(tester, find.byTooltip('5'));
    await tapText(tester, 'Submit rating');
    await pumpUntil(tester, find.text('Thanks for your rating!'));
  });
}
