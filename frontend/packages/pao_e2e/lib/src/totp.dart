import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

/// The RFC 6238 code (HMAC-SHA1, 30 s, 6 digits) an authenticator app shows
/// for the base32 [secret] at [at].
String totp(String secret, DateTime at) {
  final counter = at.millisecondsSinceEpoch ~/ 1000 ~/ 30;
  // Two 32-bit halves: dart2js has no 64-bit ByteData setters.
  final message = ByteData(8)
    ..setUint32(0, counter ~/ 0x100000000)
    ..setUint32(4, counter % 0x100000000);
  final sum = Hmac(sha1, _base32(secret)).convert(message.buffer.asUint8List());
  final bytes = sum.bytes;
  final offset = bytes.last & 0x0f;
  final code =
      ByteData.sublistView(
        Uint8List.fromList(bytes),
        offset,
        offset + 4,
      ).getUint32(0) &
      0x7fffffff;
  return (code % 1000000).toString().padLeft(6, '0');
}

/// When the code after the one valid at [at] becomes valid.
DateTime nextTotpWindow(DateTime at) {
  final seconds = at.millisecondsSinceEpoch ~/ 1000;
  return DateTime.fromMillisecondsSinceEpoch(
    (seconds - seconds % 30 + 30) * 1000,
  );
}

List<int> _base32(String secret) {
  final out = <int>[];
  var buffer = 0;
  var bits = 0;
  for (final char in secret.toUpperCase().replaceAll('=', '').split('')) {
    final value = _alphabet.indexOf(char);
    if (value < 0) throw FormatException('not base32: $secret');
    // Only the bits not yet emitted are kept, so this stays within the 32
    // bits web integers allow.
    buffer = ((buffer << 5) | value) & 0xfff;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      out.add((buffer >> bits) & 0xff);
    }
  }
  return out;
}
