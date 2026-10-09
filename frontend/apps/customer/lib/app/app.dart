import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Root widget of PAO: theme, language and the guarded router.
class PaoApp extends StatefulWidget {
  /// Creates the app root.
  const PaoApp({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<PaoApp> createState() => _PaoAppState();
}

class _PaoAppState extends State<PaoApp> {
  late final GoRouter _router = appRouter(widget.services);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: widget.services.locale,
    builder: (_, locale, _) => MaterialApp.router(
      title: 'PAO',
      theme: PaoTheme.light(),
      locale: locale,
      supportedLocales: PaoLocales.all,
      localizationsDelegates: const [
        PaoL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    ),
  );
}
