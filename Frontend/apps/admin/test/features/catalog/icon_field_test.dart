import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/catalog/data/api_catalog_repository.dart';
import 'package:pao_admin/features/catalog/presentation/icon_field.dart';
import 'package:pao_admin/features/catalog/presentation/icon_source_tabs.dart';
import 'package:pao_admin/shared/image_file.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../support/harness.dart';

const _icons = '/v1/admin/catalog/icons';
const _link = '/v1/admin/catalog/icons/from-link';
const _stored =
    'https://cdn.example/catalog-icons/0123456789abcdef0123456789abcdef.svg';

Map<String, Object?> _refused(String reason) => {
  'error': {
    'code': 'VALIDATION_FAILED',
    'message': 'Invalid request.',
    'details': {'reason': reason},
  },
};

class _Selector extends FileSelectorPlatform with MockPlatformInterfaceMixin {
  List<XTypeGroup>? asked;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    asked = acceptedTypeGroups;
    return XFile.fromData(Uint8List(1), name: 'a.svg', path: 'a.svg');
  }
}

void main() {
  late Harness h;
  late TextEditingController key;
  late ValueNotifier<String?> url;

  setUp(() {
    h = Harness.create();
    key = TextEditingController(text: 'plumbing');
    url = ValueNotifier(null);
  });

  Future<void> pump(WidgetTester tester, [ImageFileChooser? choose]) async {
    desktop(tester);
    await pumpPage(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(PaoSpace.lg),
          child: IconField(
            keyController: key,
            url: url,
            icons: ApiCatalogRepository(h.services.api),
            error: 'Bad key',
            chooseFile: choose ?? () async => null,
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, [String? tab]) async {
    await tester.tap(find.text('Choose icon'));
    await tester.pumpAndSettle();
    if (tab != null) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('a library icon is found by search and picked', (tester) async {
    h.http.onGet(
      _icons,
      (s) => s.reply(200, {
        'keys': ['plumbing', 'spa', 'salon'],
      }),
    );
    await pump(tester);
    expect(find.text('Bad key'), findsOneWidget);
    expect(find.textContaining('at least 96 × 96'), findsOneWidget);
    expect(find.byType(PaoIconTile), findsNWidgets(2));
    await open(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      'sa',
    );
    await tester.pumpAndSettle();
    expect(find.text('spa'), findsNothing);
    await tester.tap(find.text('salon'));
    await tester.pumpAndSettle();
    expect((key.text, url.value), ('salon', null));
  });

  testWidgets('without the list the picker offers the keys the apps ship', (
    tester,
  ) async {
    h.http.onGet(_icons, (s) => s.reply(500, _refused('x')));
    await pump(tester);
    await open(tester);
    expect(find.text('electrician'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect((key.text, url.value), ('plumbing', null));
  });

  testWidgets('an uploaded file becomes the icon until the library is chosen', (
    tester,
  ) async {
    h.http.onPost(
      _icons,
      (s) => s.reply(201, {'iconUrl': _stored, 'contentType': 'image/svg+xml'}),
    );
    final svg = Uint8List.fromList(utf8.encode('<svg/>'));
    await pump(
      tester,
      () async => XFile.fromData(svg, name: 'Tap.SVG', path: 'Tap.SVG'),
    );
    await open(tester, 'Upload');
    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();
    expect(url.value, _stored);
    expect(h.bodyOf(_icons), {
      'contentType': 'image/svg+xml',
      'data': base64Encode(svg),
    });
    expect(find.text('Uploaded icon'), findsOneWidget);
    await tester.tap(find.text('Use the library icon'));
    await tester.pumpAndSettle();
    expect((key.text, url.value), ('plumbing', null));
  });

  testWidgets('a refused or unknown file keeps the picker open with why', (
    tester,
  ) async {
    h.http.onPost(_icons, (s) => s.reply(422, _refused('icon_opaque')));
    var files = [
      XFile.fromData(Uint8List(8), name: 'a.png', mimeType: 'image/png'),
      XFile.fromData(Uint8List(8), name: 'a.gif', path: 'a.gif'),
      null,
    ];
    await pump(tester, () async => files.removeAt(0));
    await open(tester, 'Upload');
    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();
    expect(find.text('The image needs a transparent background.'), findsOne);
    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();
    expect(find.text('This is not a readable SVG, PNG or WebP.'), findsOne);
    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();
    expect(url.value, isNull);
    files = [];
  });

  testWidgets('a link is stored once the backend downloads it', (tester) async {
    h.http.onPost(_link, (s) => s.reply(422, _refused('icon_link_failed')));
    await pump(tester);
    await open(tester, 'From link');
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      ' https://example.com/a.svg ',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('The link could not be downloaded.'), findsOneWidget);
    expect(h.bodyOf(_link), {'url': 'https://example.com/a.svg'});
    h.http.onPost(
      _link,
      (s) => s.reply(201, {'iconUrl': _stored, 'contentType': 'image/svg+xml'}),
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(url.value, _stored);
  });

  testWidgets('every refusal has words and other failures the common ones', (
    tester,
  ) async {
    await pump(tester);
    final context = tester.element(find.byType(IconField));
    const reasons = {
      'icon_too_large': 'The file is too large.',
      'icon_not_square': 'The image must be square.',
      'icon_too_small': 'The image must be at least 96 × 96.',
    };
    for (final MapEntry(:key, :value) in reasons.entries) {
      final failure = ApiFailure(
        'VALIDATION_FAILED',
        status: 422,
        details: {'reason': key},
      );
      expect(iconFailureText(context, failure), value);
    }
    expect(iconFailureText(context, const NetworkFailure()), isNotNull);
    expect(iconFailureText(context, null), isNull);
    expect(imageType('application/octet-stream', 'x.webp'), 'image/webp');
    expect(imageType('image/png', 'x.bin'), 'image/png');
    expect(imageType(null, 'x.png'), 'image/png');
  });

  test('the default chooser asks the browser for svg, png and webp', () async {
    final selector = _Selector();
    FileSelectorPlatform.instance = selector;
    expect((await chooseImageFile())?.name, 'a.svg');
    expect(selector.asked!.single.extensions, ['svg', 'png', 'webp']);
  });
}
