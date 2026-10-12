import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pao_core/src/env.dart';
import 'package:pao_core/src/http/pinning_web.dart'
    if (dart.library.io) 'package:pao_core/src/http/pinning_io.dart';
import 'package:pao_core/src/http/pins.dart';

/// The pinning adapter for release builds given `PAO_PIN_SHA256`, else null.
///
/// Debug and test builds never pin: they talk to local stacks and to
/// intercepting proxies on purpose.
HttpClientAdapter? pinningAdapter(Env env, {bool release = kReleaseMode}) {
  final pins = CertificatePins.parse(env.certificatePins ?? '');
  if (!release || pins.isEmpty) return null;
  return pinnedAdapter(pins);
}
