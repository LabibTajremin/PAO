import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _Paths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _Paths(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

const _svgUrl = 'https://cdn.example/artwork/offline/a.svg';
const _pngUrl = 'https://cdn.example/artwork/empty.jobs/b.png';

Map<String, Object?> _config({int version = 1}) => {
  'tagline': {'en': 'Need it? PAO it.', 'bn': 'চাইলেই PAO'},
  'artwork': [
    {'key': 'offline', 'url': _svgUrl, 'version': version},
    {'key': 'empty.jobs', 'url': _pngUrl, 'version': 1},
  ],
};

void main() {
  late Dio api;
  late DioAdapter server;
  late Dio files;
  late DioAdapter storage;
  late MemoryLookStore store;

  setUp(() {
    api = Dio(BaseOptions(baseUrl: 'http://api.test'));
    server = DioAdapter(dio: api);
    files = Dio();
    storage = DioAdapter(dio: files);
    store = MemoryLookStore();
  });

  AppLookService service() =>
      AppLookService(api, store, app: 'partner', files: files);

  test('a fresh install fetches the look and caches it', () async {
    server.onGet(
      '/v1/app-config',
      queryParameters: {'app': 'partner'},
      (s) => s.reply(
        200,
        _config(),
        headers: {
          'etag': ['"v1"'],
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    storage
      ..onGet(_svgUrl, (s) => s.reply(200, utf8.encode('<svg/>')))
      ..onGet(_pngUrl, (s) => s.reply(500, null));
    final look = service();
    await look.start();
    expect(look.look.value.tagline('bn'), 'চাইলেই PAO');
    expect(look.look.value.tagline('en'), 'Need it? PAO it.');
    expect(look.look.value.artwork.keys, ['offline']);
    expect(look.look.value.artwork['offline']!.isSvg, isTrue);
    expect(store.files.keys, containsAll(['config.json', 'offline-1.svg']));
    expect(
      (jsonDecode(utf8.decode(store.files['config.json']!)) as Map)['etag'],
      '"v1"',
    );
  });

  test('a cached look shows at once and a 304 keeps it', () async {
    store.files['config.json'] = utf8.encode(
      jsonEncode({..._config(), 'etag': '"v1"'}),
    );
    store.files['offline-1.svg'] = Uint8List.fromList(utf8.encode('<svg/>'));
    store.files['empty.jobs-1.img'] = Uint8List.fromList([1, 2]);
    server.onGet(
      '/v1/app-config',
      queryParameters: {'app': 'partner'},
      headers: {'If-None-Match': '"v1"'},
      (s) => s.reply(304, null),
    );
    final look = service();
    await look.start();
    expect(look.look.value.artwork['empty.jobs']!.isSvg, isFalse);
    expect(look.look.value.artwork.length, 2);
  });

  test('offline, the app keeps the seed look', () async {
    server.onGet(
      '/v1/app-config',
      queryParameters: {'app': 'partner'},
      (s) => s.throws(
        0,
        DioException.connectionError(
          requestOptions: RequestOptions(),
          reason: 'offline',
        ),
      ),
    );
    final look = service();
    await look.start();
    expect(look.look.value.tagline('en'), AppLook.seedTaglineEn);
    expect(const AppLook().tagline('bn'), AppLook.seedTaglineBn);
  });

  test('files are stored in the support folder', () async {
    final root = Directory.systemTemp.createTempSync('look');
    addTearDown(() => root.deleteSync(recursive: true));
    PathProviderPlatform.instance = _Paths(root.path);
    final fileStore = await FileLookStore.support();
    expect(await fileStore.read('x'), isNull);
    await fileStore.write('x', [7]);
    expect(await fileStore.read('x'), [7]);
    expect(File('${root.path}/look/x').existsSync(), isTrue);
    AppLookService(Dio(), fileStore, app: 'customer');
  });

  testWidgets('the slot follows the look', (tester) async {
    final look = ValueNotifier(const AppLook());
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(width: 200, child: LookArtwork(look, 'offline')),
      ),
    );
    expect(tester.widget<PaoArtwork>(find.byType(PaoArtwork)).image, isNull);
    look.value = AppLook(
      artwork: {
        'offline': LookImage(
          Uint8List.fromList(utf8.encode('<svg/>')),
          isSvg: true,
          version: 2,
        ),
      },
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaoArtwork), findsOneWidget);
    expect(tester.widget<PaoArtwork>(find.byType(PaoArtwork)).image, isNotNull);
  });
}
