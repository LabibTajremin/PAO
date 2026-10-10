import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_detail_page.dart';
import 'package:pao_admin/features/complaints/presentation/complaints_page.dart';

import '../../support/harness.dart';
import '../providers/fixtures.dart';
import 'fixtures.dart';

const _list = '/v1/admin/complaints';

void main() {
  testWidgets('the queue filters by status and "assigned to me"', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(
        _list,
        (s) => s.reply(200, {
          'items': [
            complaint(),
            complaint(status: 'assigned', reporterRole: 'provider'),
          ],
        }),
      )
      ..onGet('/v1/me', (s) => s.reply(200, me()));
    await h.pumpApp(tester, Routes.complaints);
    expect(find.text('TCK-002341'), findsNWidgets(2));
    expect(find.text('Poor quality'), findsNWidgets(2));
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('8 Oct, 10:00 AM'), findsNWidgets(2));

    await choose(tester, h, 'Status: Any', 'Assigned');
    var sent = h.sent.lastWhere((o) => o.path == _list).queryParameters;
    expect(sent['status'], 'assigned');
    expect(sent.containsKey('assigneeId'), isFalse);

    await tester.tap(find.text('Assigned to me'));
    await h.settle(tester);
    sent = h.sent.lastWhere((o) => o.path == _list).queryParameters;
    expect(sent['assigneeId'], meId);
    await tester.tap(find.text('Assigned to me'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.path == '/v1/me'), hasLength(1));

    await tester.tap(find.text('TCK-002341').first);
    await h.settle(tester);
    expect(find.byType(ComplaintDetailPage), findsOneWidget);
  });

  testWidgets('an empty or failed queue says so', (tester) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_list, (s) => s.reply(200, {'items': <Object?>[]}));
    await h.pumpApp(tester, Routes.complaints);
    expect(find.text('No complaints match these filters.'), findsOneWidget);
    h.http.onGet('/v1/me', (s) => s.reply(500, apiError('INTERNAL')));
    await tester.tap(find.text('Assigned to me'));
    await h.settle(tester);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('the back link returns to the queue', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet('$_list/$complaintId', (s) => s.reply(404, apiError('NOT_FOUND')))
      ..onGet('/v1/me', (s) => s.reply(200, me()))
      ..onGet(_list, (s) => s.reply(200, {'items': <Object?>[]}));
    await h.pumpApp(tester, Routes.detail(Routes.complaints, complaintId));
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet('$_list/$complaintId', (s) => s.reply(200, complaint()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('The fan still wobbles after installation.'), findsOne);
    await tester.tap(find.text('All complaints'));
    await h.settle(tester);
    expect(find.byType(ComplaintsPage), findsOneWidget);
  });
}
