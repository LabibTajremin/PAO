import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pao_core/src/appearance/app_look.dart';
import 'package:pao_core/src/appearance/look_store.dart';

/// Keeps [look] in step with `GET /v1/app-config` (ADR-0040): the cached copy
/// at start, then the server's when it changed (ETag), downloading only
/// illustrations whose version is new. Failures keep what is cached, so the
/// app works offline and never waits for this.
class AppLookService {
  /// Creates the service for [app] (`customer` or `partner`); [files]
  /// downloads illustrations and must not carry the API's credentials.
  AppLookService(this._api, this._store, {required this.app, Dio? files})
    : _files = files ?? Dio();

  final Dio _api;
  final Dio _files;
  final LookStore _store;

  /// `customer` or `partner`.
  final String app;

  /// What the app shows now.
  final ValueNotifier<AppLook> look = ValueNotifier(const AppLook());

  static const _configName = 'config.json';

  /// Shows the cached look, then refreshes it.
  Future<void> start() async {
    final cached = await _store.read(_configName);
    if (cached != null) {
      look.value = await _apply(
        jsonDecode(utf8.decode(cached)) as Map<String, Object?>,
      );
    }
    await refresh();
  }

  /// Asks the server whether the look changed and applies it if so.
  Future<void> refresh() async {
    try {
      final cached = await _store.read(_configName);
      final etag = cached == null
          ? null
          : (jsonDecode(utf8.decode(cached)) as Map)['etag'] as String?;
      final res = await _api.get<Map<String, Object?>>(
        '/v1/app-config',
        queryParameters: {'app': app},
        options: Options(
          headers: etag == null ? null : {'If-None-Match': etag},
          validateStatus: (s) => s == 200 || s == 304,
        ),
      );
      if (res.statusCode == 304) return;
      final body = {...res.data!, 'etag': res.headers.value('etag')};
      look.value = await _apply(body);
      await _store.write(_configName, utf8.encode(jsonEncode(body)));
    } on DioException {
      // Offline or the server is away: keep showing what is cached.
    }
  }

  Future<AppLook> _apply(Map<String, Object?> config) async {
    final tagline = config['tagline']! as Map<String, Object?>;
    final artwork = <String, LookImage>{};
    for (final item in config['artwork']! as List<Object?>) {
      final entry = item! as Map<String, Object?>;
      if (await _image(entry) case final image?) {
        artwork[entry['key']! as String] = image;
      }
    }
    return AppLook(
      taglineEn: tagline['en']! as String,
      taglineBn: tagline['bn']! as String,
      artwork: artwork,
    );
  }

  Future<LookImage?> _image(Map<String, Object?> entry) async {
    final url = entry['url']! as String;
    final version = entry['version']! as int;
    final isSvg = Uri.parse(url).path.toLowerCase().endsWith('.svg');
    final name = '${entry['key']}-$version.${isSvg ? 'svg' : 'img'}';
    var bytes = await _store.read(name);
    if (bytes == null) {
      try {
        final res = await _files.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        bytes = Uint8List.fromList(res.data!);
        await _store.write(name, bytes);
      } on DioException {
        // Not cached and not reachable: the bundled seed shows until next time.
        return null;
      }
    }
    return LookImage(bytes, isSvg: isSvg, version: version);
  }
}
