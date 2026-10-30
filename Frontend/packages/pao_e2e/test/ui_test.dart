import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_ui/pao_ui.dart';

Future<void> _pump(WidgetTester tester, List<Widget> children) =>
    tester.pumpWidget(
      MaterialApp(
        theme: PaoTheme.light(),
        home: Scaffold(body: ListView(children: children)),
      ),
    );

void main() {
  testWidgets('waits, scrolls lazily built lists, taps and types', (
    tester,
  ) async {
    final name = TextEditingController();
    String? code;
    var tapped = 0;
    await _pump(tester, [
      PaoTextField(label: 'Name', controller: name),
      PaoOtpInput(onCompleted: (c) => code = c),
      for (var i = 0; i < 40; i++) SizedBox(height: 80, child: Text('row $i')),
      TextButton(onPressed: () => tapped++, child: const Text('Far away')),
    ]);
    await typeInto(tester, 'Name', 'Nusrat');
    await enterCode(tester, '123456');
    expect([name.text, code], ['Nusrat', '123456']);
    expect(shownTexts(), contains('Name'));
    await tapText(tester, 'Far away');
    expect(tapped, 1);
    await pumpUntil(tester, find.textContaining('row'), atLeast: 2);
    name.dispose();
  });

  testWidgets('says what was on screen when the wait runs out', (tester) async {
    await _pump(tester, [const Text('only this')]);
    expect(
      await _failure(
        () => pumpUntil(tester, find.text('missing'), timeout: _short),
      ),
      contains('only this'),
    );
    expect(
      await _failure(
        () => reveal(tester, find.text('missing'), timeout: _short),
      ),
      contains('looking for'),
    );
  });

  testWidgets('reveal waits without a list to scroll', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: Text('plain'))),
    );
    expect(
      await _failure(
        () => reveal(tester, find.text('missing'), timeout: _short),
      ),
      contains('plain'),
    );
  });
}

const _short = Duration(milliseconds: 200);

Future<String?> _failure(Future<void> Function() wait) async {
  try {
    await wait();
  } on TestFailure catch (e) {
    return e.message;
  }
  return null;
}
