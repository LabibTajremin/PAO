import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/verification/presentation/queue_page.dart';
import 'package:pao_api/pao_api.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _base = '/v1/admin/verifications';
const _review = '$_base/$rahim';

Future<Harness> _open(
  WidgetTester tester, {
  List<String>? permissions,
  Map<String, Object?>? body,
}) async {
  final h = Harness.create();
  await h.signIn(tester, permissions: permissions);
  h.http.onGet(_review, (s) => s.reply(200, body ?? reviewJson()));
  await h.pumpApp(tester, Routes.reviewOf(rahim));
  return h;
}

Finder _in(ItemType type, String text) =>
    find.descendant(of: find.byKey(ValueKey(type)), matching: find.text(text));

Future<void> _key(
  WidgetTester tester,
  Harness h,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyEvent(key);
  await h.settle(tester);
}

void main() {
  testWidgets('the review shows the profile, face check and every item', (
    tester,
  ) async {
    desktop(tester);
    tester.view.physicalSize = const Size(1280, 3200);
    await _open(tester);
    expect(find.text('Rahim Uddin'), findsWidgets);
    expect(find.text('Level 0 · Registered'), findsOneWidget);
    expect(find.text('1990123456789'), findsOneWidget);
    expect(find.text('17 May 1990'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Not given'), findsOneWidget);
    expect(find.text('Compare the selfie with the NID photo'), findsOneWidget);
    expect(find.text('NID front · NID back'), findsOneWidget);
    expect(find.text('Rejected: Name mismatch'), findsOneWidget);
    expect(find.text('Expires 1 Mar 2027'), findsOneWidget);
    expect(find.text('Decided 1 Oct 2026, 12:00 PM'), findsOneWidget);
    expect(find.text('Issue date: 2026-03-01'), findsOneWidget);
    expect(find.text('Relation: Uncle'), findsOneWidget);
    expect(find.text('custom: x'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.text('Approve'), findsNWidgets(2));
  });

  testWidgets('approve and reject with a reason template', (tester) async {
    desktop(tester);
    final h = await _open(tester);
    h.http.onPost(
      '$_review/items/nid/approve',
      (s) => s.reply(200, reviewJson(items: defaultItems().sublist(1))),
    );
    await tester.tap(_in(ItemType.nid, 'Approve'));
    await h.settle(tester);
    expect(
      find.text('Saved. The provider is now at Level 0 · Registered.'),
      findsOneWidget,
    );
    h.http.onPost(
      '$_review/items/selfie/reject',
      (s) => s.reply(200, reviewDone()),
    );
    await tester.tap(_in(ItemType.selfie, 'Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Reject Live selfie'), findsOneWidget);
    await tester.tap(find.text('The selfie does not match the NID photo.'));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Reject'),
      ),
    );
    await h.settle(tester);
    expect(h.bodyOf('$_review/items/selfie/reject'), {
      'reason': 'The selfie does not match the NID photo.',
    });
    expect(find.text('Level 1 · Verified'), findsOneWidget);
    expect(find.text('Nothing is waiting for a decision.'), findsOneWidget);
  });

  testWidgets('a cancelled reject sends nothing; a failed one says why', (
    tester,
  ) async {
    desktop(tester);
    final h = await _open(tester);
    await tester.tap(_in(ItemType.nid, 'Reject'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.method == 'POST'), isEmpty);
    h.http.onPost(
      '$_review/items/nid/approve',
      (s) => s.reply(409, apiError('ITEM_NOT_PENDING')),
    );
    await tester.tap(_in(ItemType.nid, 'Approve'));
    await h.settle(tester);
    expect(find.text('This item is not waiting for review.'), findsOneWidget);
  });

  testWidgets('keys approve, reject, move and open the next provider', (
    tester,
  ) async {
    desktop(tester);
    final h = await _open(tester);
    h.http.onPost(
      '$_review/items/nid/approve',
      (s) => s.reply(200, reviewJson()),
    );
    await _key(tester, h, LogicalKeyboardKey.keyA);
    expect(h.sent.last.path, '$_review/items/nid/approve');
    await _key(tester, h, LogicalKeyboardKey.arrowDown);
    await _key(tester, h, LogicalKeyboardKey.keyR);
    expect(find.text('Reject Live selfie'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await _key(tester, h, LogicalKeyboardKey.arrowUp);
    await tester.tap(_in(ItemType.selfie, 'Live selfie').first);
    await tester.pumpAndSettle();
    h.http.onGet(_base, (s) => s.reply(200, queue([queueRow()])));
    await _key(tester, h, LogicalKeyboardKey.keyN);
    expect(find.text('No other providers are waiting.'), findsOneWidget);
    h.http
      ..onGet(_base, (s) => s.reply(200, queue([queueRow(id: karim)])))
      ..onGet(
        '$_base/$karim',
        (s) => s.reply(200, reviewJson(id: karim, level: 1)),
      );
    await tester.tap(find.text('Next provider'));
    await h.settle(tester);
    expect(find.text('Level 1 · Verified'), findsOneWidget);
    expect(h.sent.last.path, '$_base/$karim');
  });

  testWidgets('without permissions the actions and documents are hidden', (
    tester,
  ) async {
    narrow(tester);
    final h = await _open(tester, permissions: ['provider:read']);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('You may not open documents'), findsWidgets);
    await _key(tester, h, LogicalKeyboardKey.keyA);
    expect(h.sent.where((o) => o.method == 'POST'), isEmpty);
    await tester.tap(find.byTooltip('Back to the queue'));
    await h.settle(tester);
    expect(find.byType(QueuePage), findsOneWidget);
  });

  testWidgets('a failed review can be retried', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_review, (s) => s.reply(404, apiError('NOT_FOUND')));
    await h.pumpApp(tester, Routes.reviewOf(rahim));
    expect(find.text('Verification review'), findsOneWidget);
    expect(find.text('We could not find that.'), findsOneWidget);
    h.http.onGet(_review, (s) => s.reply(200, reviewJson(face: null)));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Not checked yet'), findsOneWidget);
  });
}
