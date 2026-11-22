import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: PaoTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  String? assetOf(WidgetTester tester) => tester
      .widgetList<SvgPicture>(find.byType(SvgPicture))
      .map((p) => p.bytesLoader)
      .whereType<SvgAssetLoader>()
      .map((l) => l.assetName)
      .firstOrNull;

  test('the key list matches the shipped icon files', () {
    final shipped =
        Directory('assets/icons')
            .listSync()
            .map((f) => f.uri.pathSegments.last.replaceAll('.svg', ''))
            .toList()
          ..sort();
    expect([...paoIconKeys]..sort(), shipped);
    expect(PaoServiceIcon.assetFor('plumbing'), 'assets/icons/plumbing.svg');
    expect(PaoServiceIcon.assetFor('bolt'), 'assets/icons/tools.svg');
  });

  testWidgets('a library key draws its icon in the given colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const PaoServiceIcon('catering', color: Colors.red)),
    );
    expect(assetOf(tester), 'assets/icons/catering.svg');
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      svg.colorFilter,
      const ColorFilter.mode(Colors.red, BlendMode.srcIn),
    );
    expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
  });

  testWidgets('the service tile tints the icon with the accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(PaoIconTile.service(iconKey: 'unknown', size: 64, key: UniqueKey())),
    );
    final icon = tester.widget<PaoServiceIcon>(find.byType(PaoServiceIcon));
    final context = tester.element(find.byType(PaoServiceIcon));
    expect((icon.size, icon.color), (32.0, context.pao.action));
    expect(assetOf(tester), 'assets/icons/tools.svg');
  });

  testWidgets('an uploaded svg loads from its url, the library as fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const PaoServiceIcon(
          'plumbing',
          iconUrl: 'https://cdn.example/catalog-icons/a.SVG?v=1',
        ),
      ),
    );
    expect(
      tester.widget<SvgPicture>(find.byType(SvgPicture).first).bytesLoader,
      isA<SvgNetworkLoader>(),
    );
    expect(assetOf(tester), isNull);
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(assetOf(tester), 'assets/icons/plumbing.svg');
  });

  testWidgets('an uploaded png is masked with the colour', (tester) async {
    await tester.pumpWidget(
      app(
        const IconTheme(
          data: IconThemeData(color: Colors.green),
          child: PaoServiceIcon(
            'spa',
            iconUrl: 'https://cdn.example/catalog-icons/a.png',
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.color, image.colorBlendMode),
      (Colors.green, BlendMode.srcIn),
    );
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(assetOf(tester), 'assets/icons/spa.svg');
  });
}
