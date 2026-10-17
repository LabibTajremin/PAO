import 'package:pao_core/pao_core.dart';

/// Whether this device has finished onboarding.
bool onboarded(Prefs prefs) => prefs.flag(Prefs.onboardedKey);

/// Remembers the chosen [languageCode] and that onboarding is done (C-15).
Future<void> completeOnboarding(Prefs prefs, String languageCode) async {
  await prefs.setString(Prefs.languageKey, languageCode);
  await prefs.setFlag(Prefs.onboardedKey, value: true);
}
