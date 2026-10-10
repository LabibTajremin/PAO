import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Localisation delegates of the admin panel.
const adminDelegates = <LocalizationsDelegate<Object>>[
  AdminL10n.delegate,
  PaoL10n.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Root widget of PAO Admin: theme, language and the guarded router.
class PaoApp extends StatefulWidget {
  /// Creates the app root; [initial] is the first location.
  const PaoApp({
    required this.services,
    this.initial = Routes.dashboard,
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
  late final GoRouter _router = adminRouter(
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
      title: 'PAO Admin',
      theme: PaoTheme.light(),
      locale: locale,
      supportedLocales: PaoLocales.all,
      localizationsDelegates: adminDelegates,
      routerConfig: _router,
    ),
  );
}
