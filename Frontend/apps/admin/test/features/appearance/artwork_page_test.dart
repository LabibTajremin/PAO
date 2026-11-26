import 'dart:typed_data';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_ui/pao_ui.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../support/harness.dart';
import '../settings/fixtures.dart';

const _artwork = '/v1/admin/artwork';

class _Files extends FileSelectorPlatform with MockPlatformInterfaceMixin {
  final queue = <XFile?>[];

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => queue.removeAt(0);
}

Map<String, Object?> _slot(
  String key, {
  String? url,
  bool replaced = false,
  int version = 1,
}) => {
  'key': key,
  'app': key.startsWith('partner') ? 'partner' : 'customer',
  'width': key == 'customer.signin.hero' ? 1170 : 720,
  'height': key == 'customer.signin.hero' ? 1200 : 540,
  'url': ?url,
  'contentType': ?(url == null ? null : 'image/svg+xml'),
  'version': url == null ? 0 : version,
  'replaced': replaced,
};

Map<String, Object?> _refused(
  String reason, [
  Map<String, Object?> more = const {},
]) => {
  'error': {
    'code': 'VALIDATION_FAILED',
    'message': 'Invalid request.',
    'details': {'reason': reason, ...more},
  },
};

Map<String, Object?> _list() => {
  'slots': [
    _slot(
      'customer.signin.hero',
      url: 'https://cdn.example/artwork/hero.svg',
      replaced: true,
      version: 3,
    ),
    _slot('offline', url: 'https://cdn.example/artwork/offline.png'),
    _slot('success.job'),
  ],
};

void main() {
  late _Files files;

  setUp(() {
    files = _Files();
    FileSelectorPlatform.instance = files;
  });

  Future<Harness> open(WidgetTester tester, {List<String>? permissions}) async {
    desktop(tester);
    final h = Harness.create();
    h.http.onGet(_artwork, (s) => s.reply(200, _list()));
    await h.signIn(tester, permissions: permissions);
    await h.pumpApp(tester, Routes.appearance);
    return h;
  }

  Future<void> upload(WidgetTester tester, int card) async {
    await tester.tap(find.text('Upload').at(card));
    await tester.pumpAndSettle();
  }

  testWidgets('each slot shows its size, status and safe area', (tester) async {
    await open(tester);
    expect(find.text('Illustrations'), findsWidgets);
    expect(find.text('1170 × 1200 px · Uploaded'), findsOneWidget);
    expect(find.text('720 × 540 px · Original'), findsOneWidget);
    expect(find.text('720 × 540 px · Shown from the app'), findsOneWidget);
    expect(find.byType(PaoRemoteImage), findsNWidgets(4));
    expect(find.byType(FractionallySizedBox), findsNWidgets(8));
  });

  testWidgets('an upload is sent as base64 and the list reloads', (
    tester,
  ) async {
    final h = await open(tester);
    h.http.onPut(
      '$_artwork/offline',
      (s) => s.reply(
        200,
        _slot('offline', url: 'https://cdn.example/n.svg', replaced: true),
      ),
    );
    files.queue.add(
      XFile.fromData(
        Uint8List.fromList([60, 115]),
        name: 'a.svg',
        path: 'a.svg',
      ),
    );
    await upload(tester, 1);
    expect(find.text('Saved.'), findsOneWidget);
    expect(h.bodyOf('$_artwork/offline'), {
      'contentType': 'image/svg+xml',
      'data': 'PHM=',
    });
  });

  testWidgets('refusals say why, with the size the slot needs', (tester) async {
    final h = await open(tester);
    files.queue.addAll([
      XFile.fromData(Uint8List(4), name: 'a.png', path: 'a.png'),
      XFile.fromData(Uint8List(4), name: 'a.png', path: 'a.png'),
      XFile.fromData(Uint8List(4), name: 'a.png', path: 'a.png'),
      XFile.fromData(Uint8List(4), name: 'a.gif', path: 'a.gif'),
      null,
    ]);
    h.http.onPut(
      '$_artwork/customer.signin.hero',
      (s) => s.reply(
        422,
        _refused('artwork_wrong_size', {'expected': '1170x1200'}),
      ),
    );
    await upload(tester, 0);
    expect(
      find.text('Use an image of 1170x1200 pixels, or an SVG with that ratio.'),
      findsOneWidget,
    );
    h.http.onPut(
      '$_artwork/customer.signin.hero',
      (s) => s.reply(422, _refused('artwork_too_large')),
    );
    await upload(tester, 0);
    expect(find.textContaining('The file is too large'), findsOneWidget);
    h.http.onPut(
      '$_artwork/customer.signin.hero',
      (s) => s.reply(422, _refused('artwork_opaque')),
    );
    await upload(tester, 0);
    expect(
      find.text('The image needs a transparent background.'),
      findsOneWidget,
    );
    await upload(tester, 0);
    expect(
      find.text('This is not a readable SVG, PNG or WebP.'),
      findsOneWidget,
    );
    await upload(tester, 0);
    expect(
      find.text('This is not a readable SVG, PNG or WebP.'),
      findsOneWidget,
    );
  });

  testWidgets('an uploaded slot goes back to its original', (tester) async {
    final h = await open(tester);
    h.http.onDelete(
      '$_artwork/customer.signin.hero',
      (s) => s.reply(
        200,
        _slot('customer.signin.hero', url: 'https://cdn.example/s.svg'),
      ),
    );
    await tester.tap(find.text('Use the original').first);
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    h.http.onDelete(
      '$_artwork/customer.signin.hero',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await tester.tap(find.text('Use the original').first);
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsNothing);
  });

  testWidgets('without settings:manage the slots are read-only', (
    tester,
  ) async {
    await open(tester, permissions: ['settings:read']);
    final upload = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Upload').first,
    );
    expect(upload.onPressed, isNull);
  });

  testWidgets('settings opens the illustrations page', (tester) async {
    final h = await openSettings(tester, Routes.settings);
    h.http.onGet(_artwork, (s) => s.reply(200, _list()));
    await tester.tap(find.text('Illustrations'));
    await tester.pumpAndSettle();
    expect(find.text('1170 × 1200 px · Uploaded'), findsOneWidget);
  });
}
