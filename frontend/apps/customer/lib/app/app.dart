import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/notifications/data/api_notifications_repository.dart';
import 'package:pao_customer/features/notifications/data/push_registrar.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Localisation delegates of the customer app.
const customerDelegates = <LocalizationsDelegate<Object>>[
  CustomerL10n.delegate,
  PaoL10n.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Root widget of PAO: theme, language, offline banner and router.
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
  late final GoRouter _router = customerRouter(
    widget.services,
    initial: widget.initial,
  );

  late final PushRegistrar _push = PushRegistrar(
    sessions: widget.services.sessions,
    push: widget.services.push,
    repo: ApiNotificationsRepository(widget.services.api),
    open: (location) => unawaited(_router.push<void>(location)),
  );

  @override
  void initState() {
    super.initState();
    _push.start();
  }

  @override
  void dispose() {
    unawaited(_push.stop());
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
      localizationsDelegates: customerDelegates,
      routerConfig: _router,
      builder: (_, child) =>
          OfflineBanner(watcher: widget.services.online, child: child!),
    ),
  );
}
