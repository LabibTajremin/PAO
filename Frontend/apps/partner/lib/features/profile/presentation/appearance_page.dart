import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Light, dark or like the phone. PAO Partner opens light; dark mode lives
/// here, one level into Profile, so it is easy to find but never in the way.
class AppearancePage extends StatelessWidget {
  /// Creates the page.
  const AppearancePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PaoAppBar(title: context.t.profAppearance),
    body: ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        PaoThemeModeSwitch(
          mode: services.themeMode,
          labels: {
            ThemeMode.light: context.t.profAppearanceLight,
            ThemeMode.dark: context.t.profAppearanceDark,
            ThemeMode.system: context.t.profAppearanceSystem,
          },
          onChanged: (mode) => unawaited(services.themeMode.select(mode)),
        ),
      ],
    ),
  );
}
