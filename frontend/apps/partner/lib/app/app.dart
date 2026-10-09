import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/router.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_ui/pao_ui.dart';

/// Localisation delegates of the partner app.
const partnerDelegates = <LocalizationsDelegate<Object>>[
  PartnerL10n.delegate,
  PaoL10n.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Root widget of PAO Partner: theme, language, offline banner and router.
class PaoApp extends StatefulWidget {
  /// Creates the app root; [initial] is the first location.
  const PaoApp({
    required this.services,
    this.initial = Routes.splash,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// First location.
  final String initial;

  @override
  State<PaoApp> createState() => _PaoAppState();
}

class _PaoAppState extends State<PaoApp> {
  late final GoRouter _router = partnerRouter(
    widget.services,
    initial: widget.initial,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: widget.services.locale,
    builder: (_, locale, _) => MaterialApp.router(
      title: 'PAO Partner',
      theme: PaoTheme.light(),
      locale: locale,
      supportedLocales: PaoLocales.all,
      localizationsDelegates: partnerDelegates,
      routerConfig: _router,
      builder: (_, child) =>
          OfflineBanner(watcher: widget.services.online, child: child!),
    ),
  );
}
