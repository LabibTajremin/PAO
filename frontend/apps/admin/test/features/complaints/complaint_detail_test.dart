import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_admin/features/customers/presentation/customer_detail_page.dart';
import 'package:pao_admin/features/providers/presentation/provider_detail_page.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import '../providers/fixtures.dart';
import 'fixtures.dart';

const _detail = '/v1/admin/complaints/$complaintId';
final String _path = Routes.detail(Routes.complaints, complaintId);

Future<Harness> _open(
  WidgetTester tester,
  Map<String, Object?> body, {
  List<String>? screens,
  List<String>? permissions,
}) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester, screens: screens, permissions: permissions);
  h.http
    ..onGet(_detail, (s) => s.reply(200, body))
    ..onGet('/v1/me', (s) => s.reply(200, me()));
  await h.pumpApp(tester, _path);
  return h;
}

String _failure(String code) =>
    failureMessage(lookupPaoL10n(const Locale('en')), code);

void main() {
  testWidgets('a complaint shows what happened, evidence and comments', (
    tester,
  ) async {
    final h = await _open(tester, complaint());
    for (final text in [
      'TCK-002341',
      'Open',
      'Poor quality',
      'Customer',
      'Nobody yet',
      'The fan still wobbles after installation.',
      'Photo 1',
      'Photo 2',
      'Opening complaint photos here is not available yet.',
      'Called the customer.',
      'You · 8 Oct 2026, 11:00 AM',
      'Agent 88888888 · 8 Oct 2026, 12:00 PM',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    await tester.tap(find.text('Open the booking'));
    await h.settle(tester);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });

  testWidgets('links open the reporter and the other party', (tester) async {
    final h = await _open(tester, complaint());
    await tester.tap(find.text("Reporter's profile"));
    await h.settle(tester);
    expect(find.byType(CustomerDetailPage), findsOneWidget);
    await h.go(tester, _path);
    await tester.tap(find.text("Other party's profile"));
    await h.settle(tester);
    expect(find.byType(ProviderDetailPage), findsOneWidget);
  });

  testWidgets('a provider report without screens shows no links', (
    tester,
  ) async {
    await _open(
      tester,
      complaint(reporterRole: 'provider', full: false),
      screens: ['A11'],
    );
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('No photos attached.'), findsOneWidget);
    expect(find.text('No comments yet.'), findsOneWidget);
    expect(find.text('Open the booking'), findsNothing);
    expect(find.text("Reporter's profile"), findsNothing);
  });

  testWidgets('assigning to me hides the button once it is mine', (
    tester,
  ) async {
    final h = await _open(tester, complaint());
    h.http.onPost(
      '$_detail/assign',
      (s) => s.reply(200, complaint(status: 'assigned', assignee: meId)),
    );
    await tester.tap(find.text('Assign to me'));
    await h.settle(tester);
    expect(h.bodyOf('$_detail/assign'), {'assigneeId': meId});
    expect(find.text('Complaint assigned.'), findsOneWidget);
    expect(find.text('Assign to me'), findsNothing);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('another agent can be picked by an admin who lists admins', (
    tester,
  ) async {
    final h = await _open(tester, complaint(assignee: otherId));
    expect(find.text('Agent 88888888'), findsOneWidget);
    h.http
      ..onGet(
        '/v1/admin/admin-users',
        (s) => s.reply(500, apiError('INTERNAL')),
      )
      ..onPost(
        '$_detail/assign',
        (s) => s.reply(409, apiError('COMPLAINT_INVALID_TRANSITION')),
      );
    await tester.tap(find.text('Assign to another agent'));
    await h.settle(tester);
    h.http.onGet(
      '/v1/admin/admin-users',
      (s) => s.reply(200, {
        'items': [
          agent(),
          agent(id: 'v1', name: 'Verifier Vai', roles: ['verifier']),
          agent(id: 'x1', name: 'Gone Agent', active: false),
          agent(id: meId, name: 'Super Sakib', roles: ['super_admin']),
        ],
      }),
    );
    await tester.tap(inDialog('Try again'));
    await h.settle(tester);
    expect(find.text('Verifier Vai'), findsNothing);
    expect(find.text('Gone Agent'), findsNothing);
    expect(find.text('Super Sakib'), findsOneWidget);
    await tester.tap(find.text('Farhana Akter'));
    await h.settle(tester);
    expect(h.bodyOf('$_detail/assign'), {'assigneeId': otherId});
    expect(find.text(_failure('COMPLAINT_INVALID_TRANSITION')), findsOneWidget);
  });

  testWidgets('the agent picker can be empty or cancelled', (tester) async {
    final h = await _open(tester, complaint());
    h.http.onGet(
      '/v1/admin/admin-users',
      (s) => s.reply(200, {'items': <Object?>[]}),
    );
    await tester.tap(find.text('Assign to another agent'));
    await h.settle(tester);
    expect(find.text('No active support agents.'), findsOneWidget);
    await tester.tap(inDialog('Cancel'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.path == '$_detail/assign'), isEmpty);
  });

  testWidgets('comments are sent, cleared, and kept when they fail', (
    tester,
  ) async {
    final h = await _open(tester, complaint());
    h.http.onPost(
      '$_detail/comments',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await tester.ensureVisible(find.text('Add comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add comment'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.path == '$_detail/comments'), isEmpty);
    final box = find.descendant(
      of: find.byType(PaoTextField),
      matching: find.byType(TextField),
    );
    await tester.enterText(box, 'Refund approved.');
    await tester.tap(find.text('Add comment'));
    await h.settle(tester);
    expect(find.text(_failure('INTERNAL')), findsOneWidget);
    expect(find.text('Refund approved.'), findsOneWidget);
    h.http.onPost(
      '$_detail/comments',
      (s) => s.reply(201, complaint(status: 'assigned', assignee: meId)),
    );
    await tester.tap(find.text('Add comment'));
    await h.settle(tester);
    expect(h.bodyOf('$_detail/comments'), {'body': 'Refund approved.'});
    expect(find.text('Comment added.'), findsOneWidget);
    expect(find.text('Refund approved.'), findsNothing);
  });

  testWidgets('resolving asks for a note and the verified flag', (
    tester,
  ) async {
    final h = await _open(
      tester,
      complaint(status: 'assigned', assignee: meId),
    );
    h.http.onPost(
      '$_detail/resolve',
      (s) => s.reply(200, complaint(status: 'resolved', assignee: meId)),
    );
    await tester.tap(find.text('Resolve'));
    await h.settle(tester);
    expect(find.text('Resolve TCK-002341'), findsOneWidget);
    await tester.tap(inDialog('Resolve'));
    await h.settle(tester);
    expect(find.text('Write at least 5 characters.'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Provider fixed it.',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.tap(inDialog('Resolve'));
    await h.settle(tester);
    expect(h.bodyOf('$_detail/resolve'), {
      'resolution': 'Provider fixed it.',
      'verified': true,
    });
    expect(find.text('Complaint resolved.'), findsOneWidget);
    expect(find.text('Provider revisited and fixed the fan.'), findsOneWidget);
    expect(find.text('Verified complaint'), findsOneWidget);
    expect(find.text('9 Oct 2026, 9:00 AM'), findsOneWidget);
    expect(find.text('Resolve'), findsNothing);
  });

  testWidgets('a cancelled resolve sends nothing', (tester) async {
    final h = await _open(tester, complaint());
    await tester.tap(find.text('Resolve'));
    await h.settle(tester);
    await tester.tap(inDialog('Cancel'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.path == '$_detail/resolve'), isEmpty);
  });

  testWidgets('a resolved complaint shows its outcome without actions', (
    tester,
  ) async {
    await _open(tester, complaint(status: 'resolved', full: false));
    expect(find.text('Not verified'), findsOneWidget);
    expect(find.text('Assign to me'), findsNothing);
  });

  testWidgets('without admin listing or complaint rights, fewer actions', (
    tester,
  ) async {
    await _open(
      tester,
      complaint(),
      permissions: ['complaint:manage', 'booking:read:any'],
    );
    expect(find.text('Assign to me'), findsOneWidget);
    expect(find.text('Assign to another agent'), findsNothing);
  });

  testWidgets('admins without complaint:manage cannot act', (tester) async {
    await _open(tester, complaint(), permissions: ['booking:read:any']);
    expect(find.text('Assign to me'), findsNothing);
    expect(find.text('Resolve'), findsNothing);
  });
}
