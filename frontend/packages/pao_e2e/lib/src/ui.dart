import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

/// Pumps frames until [finder] matches [atLeast] widgets; real network
/// replies land between frames, so journeys wait for what the user would see
/// instead of settling.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int atLeast = 1,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().length < atLeast) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure(
        'timed out after $timeout waiting for $finder; on screen: '
        '${shownTexts().join(' | ')}',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The texts on screen, to tell where a journey got stuck.
List<String> shownTexts() => [
  for (final e in find.byType(Text).evaluate()) ?(e.widget as Text).data,
];

/// Lets in-flight frames and animations run for [time].
Future<void> idle(
  WidgetTester tester, [
  Duration time = const Duration(milliseconds: 400),
]) async {
  final end = DateTime.now().add(time);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Waits for [finder], scrolling the page down while it is not built (lists
/// build lazily), then brings it into view.
Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  final lists = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure(
        'timed out after $timeout looking for $finder; on screen: '
        '${shownTexts().join(' | ')}',
      );
    }
    if (lists.evaluate().isNotEmpty) {
      await tester.drag(lists.first, const Offset(0, -200));
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.ensureVisible(finder.first);
  await tester.pump();
}

/// Waits for [finder], brings it into view and taps it.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder.first);
  await idle(tester);
}

/// Taps the widget showing [text].
Future<void> tapText(WidgetTester tester, String text) =>
    tapOn(tester, find.text(text));

/// Types [text] into the [PaoTextField] labelled [label].
Future<void> typeInto(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.widgetWithText(PaoTextField, label),
    matching: find.byType(TextField),
  );
  await reveal(tester, field);
  await tester.enterText(field, text);
  await idle(tester);
}

/// Enters a one-time [code] into the [PaoOtpInput] on screen.
Future<void> enterCode(WidgetTester tester, String code) async {
  final field = find.descendant(
    of: find.byType(PaoOtpInput),
    matching: find.byType(TextField),
  );
  await pumpUntil(tester, field);
  await tester.enterText(field, code);
  await idle(tester);
}
