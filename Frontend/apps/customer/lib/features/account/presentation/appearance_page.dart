import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Light, dark or like the phone. PAO opens light; dark mode lives here, one
/// level into Account, so it is easy to find but never in the way.
class AppearancePage extends StatelessWidget {
  /// Creates the page.
  const AppearancePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PaoAppBar(title: context.t.accountAppearance),
    body: ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        PaoThemeModeSwitch(
          mode: services.themeMode,
          labels: {
            ThemeMode.light: context.t.accountAppearanceLight,
            ThemeMode.dark: context.t.accountAppearanceDark,
            ThemeMode.system: context.t.accountAppearanceSystem,
          },
          onChanged: (mode) => unawaited(services.themeMode.select(mode)),
        ),
      ],
    ),
  );
}
