// Secrets first: a token can contain digit runs the number rules would only
// half hide.
final _rules = <(RegExp, String Function(Match))>[
  (
    RegExp(r'Bearer\s+[\w.~+/=-]+', caseSensitive: false),
    (_) => 'Bearer [token]',
  ),
  (RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]*'), (_) => '[jwt]'),
  (
    RegExp(
      r'((?:token|code|otp|password|secret|signature|credential)\w*'
      r'''["']?\s*[:=]\s*["']?)[^"'&\s,}]+''',
      caseSensitive: false,
    ),
    (m) => '${m[1]}[redacted]',
  ),
  (RegExp(r'(?:\+?88)?01[3-9]\d{8}'), (_) => '[phone]'),
  // NID numbers, other phone formats and anything else long and numeric.
  (RegExp(r'\+?\d[\d -]{7,}\d'), (_) => '[number]'),
];

/// Removes phone numbers, tokens, codes and long numbers from [text], so error
/// reports never carry personal data (PRD §6.6, §11).
String scrubPii(String text) {
  var out = text;
  for (final (pattern, replace) in _rules) {
    out = out.replaceAllMapped(pattern, replace);
  }
  return out;
}
