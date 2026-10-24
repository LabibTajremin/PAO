import 'package:flutter/material.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/src/widgets/segmented.dart';

/// English / বাংলা toggle bound to a [LocaleController]; each name is written in
/// its own language so either reader can find it.
class PaoLanguageSwitch extends StatelessWidget {
  /// Creates the switch.
  const PaoLanguageSwitch({required this.controller, super.key});

  /// The app's language.
  final LocaleController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: controller,
    builder: (context, locale, _) => PaoSegmented<String>(
      segments: const {'en': 'English', 'bn': 'বাংলা'},
      selected: locale.languageCode,
      onChanged: (code) => controller.select(Locale(code)),
    ),
  );
}
