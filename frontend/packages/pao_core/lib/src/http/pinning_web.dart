import 'package:dio/dio.dart';
import 'package:pao_core/src/http/pins.dart';

/// Browsers own TLS, so the admin web app cannot pin; it keeps the default
/// adapter.
HttpClientAdapter? pinnedAdapter(CertificatePins pins) => null;
