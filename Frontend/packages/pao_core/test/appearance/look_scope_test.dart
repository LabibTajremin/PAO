import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

void main() {
  final svg = Uint8List.fromList(
    utf8.encode('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 4 3"/>'),
  );

  testWidgets('without a scope the bundled seed shows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ScopedArtwork(offlineSlot, key: UniqueKey())),
    );
    expect(find.byType(LookArtwork), findsNothing);
    expect(tester.widget<PaoArtwork>(find.byType(PaoArtwork)).image, isNull);
  });

  testWidgets('inside a scope the admin image of the slot shows', (
    tester,
  ) async {
    final look = ValueNotifier(
      AppLook(artwork: {offlineSlot: LookImage(svg, isSvg: true, version: 2)}),
    );
    final other = ValueNotifier(const AppLook());
    Widget app(ValueNotifier<AppLook> l) => MaterialApp(
      home: LookScope(look: l, child: const ScopedArtwork(offlineSlot)),
    );
    await tester.pumpWidget(app(look));
    expect(tester.widget<PaoArtwork>(find.byType(PaoArtwork)).image, svg);
    await tester.pumpWidget(app(other));
    expect(tester.widget<PaoArtwork>(find.byType(PaoArtwork)).image, isNull);
  });

  test('only a network failure has the offline picture', () {
    expect(failureArtwork(const NetworkFailure()), isA<ScopedArtwork>());
    expect(failureArtwork(const UnexpectedFailure()), isNull);
    expect(failureArtwork(null), isNull);
  });
}
