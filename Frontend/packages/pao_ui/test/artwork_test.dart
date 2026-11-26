import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: PaoTheme.light(),
    home: Scaffold(
      body: Center(child: SizedBox(width: 300, child: child)),
    ),
  );

  final svg = Uint8List.fromList(
    utf8.encode("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 4 3'/>"),
  );

  Iterable<String> assets(WidgetTester tester) => tester
      .widgetList<SvgPicture>(find.byType(SvgPicture))
      .map((p) => p.bytesLoader)
      .whereType<SvgAssetLoader>()
      .map((l) => l.assetName);

  test('every slot has a bundled seed matching the design file', () {
    final bundled =
        Directory('assets/artwork')
            .listSync()
            .map((f) => f.uri.pathSegments.last.replaceAll('.svg', ''))
            .toList()
          ..sort();
    expect(bundled, paoArtworkSlots.keys.toList()..sort());
    for (final slot in paoArtworkSlots.keys) {
      final design = File('../../../design/illustrations/$slot.svg');
      expect(
        File(PaoArtwork.assetFor(slot)).readAsBytesSync(),
        design.readAsBytesSync(),
        reason: slot,
      );
    }
  });

  testWidgets('the seed shows until an image is cached, in the slot ratio', (
    tester,
  ) async {
    await tester.pumpWidget(app(PaoArtwork('offline', key: UniqueKey())));
    expect(assets(tester), ['assets/artwork/offline.svg']);
    expect(tester.getSize(find.byType(AspectRatio)), const Size(300, 225));
    await tester.pumpWidget(app(PaoArtwork('offline', image: svg)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader,
      isA<SvgBytesLoader>(),
    );
    expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
  });

  testWidgets('a broken png falls back to the seed', (tester) async {
    await tester.pumpWidget(
      app(PaoArtwork('success.job', image: svg, isSvg: false)),
    );
    await tester.pumpAndSettle();
    expect(assets(tester), ['assets/artwork/success.job.svg']);
  });

  testWidgets('remote images load by type and fall back', (tester) async {
    final fallback = Text('seed', key: UniqueKey());
    await tester.pumpWidget(
      app(PaoRemoteImage('https://cdn.example/a.svg?v=2', fallback: fallback)),
    );
    expect(
      tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader,
      isA<SvgNetworkLoader>(),
    );
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(find.text('seed'), findsOneWidget);
    await tester.pumpWidget(
      app(PaoRemoteImage('https://cdn.example/a.png', fallback: fallback)),
    );
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(find.text('seed'), findsOneWidget);
  });

  testWidgets('an empty state shows an illustration instead of its icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const PaoEmptyState(title: 'Nothing', illustration: Text('art'))),
    );
    expect(find.text('art'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsNothing);
  });
}
