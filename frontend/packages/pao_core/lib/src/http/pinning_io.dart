import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pao_core/src/http/pins.dart';

/// An adapter that refuses TLS connections whose leaf key is not pinned; the
/// platform still validates the chain and host name first.
HttpClientAdapter? pinnedAdapter(CertificatePins pins) => IOHttpClientAdapter(
  validateCertificate: (cert, host, port) =>
      cert != null && pins.accepts(cert.der),
);
