import 'package:flutter_test/flutter_test.dart';
import 'package:pao_e2e/stack.dart';

void main() {
  // RFC 6238 appendix B, SHA-1 key "12345678901234567890", last six digits.
  const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

  test('matches the RFC 6238 test vectors', () {
    DateTime at(int s) => DateTime.fromMillisecondsSinceEpoch(s * 1000);
    expect(totp(secret, at(59)), '287082');
    expect(totp(secret.toLowerCase(), at(1111111109)), '081804');
    expect(totp('$secret====', at(2000000000)), '279037');
  });

  test('rejects a key that is not base32', () {
    expect(() => totp('not-base32!', DateTime(2026)), throwsFormatException);
  });

  test('the next window starts on the next 30-second boundary', () {
    final at = DateTime.fromMillisecondsSinceEpoch(61500);
    expect(nextTotpWindow(at).millisecondsSinceEpoch, 90000);
  });
}
