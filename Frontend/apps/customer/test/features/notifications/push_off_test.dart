import 'package:flutter_test/flutter_test.dart';

import '../../support/harness.dart';

void main() {
  testWidgets('the inbox offers settings when notifications are blocked', (
    tester,
  ) async {
    final h = await Harness.create();
    h.push.on = false;
    h.http.onGet(
      '/v1/customer/notifications',
      (s) => s.reply(200, {'items': <Object>[], 'unreadCount': 0}),
    );
    await h.signIn(tester);
    await h.pumpApp(tester, '/notifications');
    await tester.tap(find.text('Turn on'));
    expect(h.push.settingsOpened, 1);
  });
}
