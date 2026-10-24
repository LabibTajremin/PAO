import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/onboarding/data/onboarding_prefs.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Splash (C01): first launch goes to onboarding, later ones home, where the
/// router's guard and gate take signed-out or new customers onward.
class SplashPage extends StatefulWidget {
  /// Creates the page.
  const SplashPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(
        onboarded(widget.services.prefs) ? Routes.home : Routes.onboarding,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaoIconTile(
              icon: Icons.home_repair_service_outlined,
              size: 72,
            ),
            const SizedBox(height: PaoSpace.lg),
            Text(context.t.appTitle, style: text.headlineSmall),
            const SizedBox(height: PaoSpace.xs),
            Text(context.t.onbTagline, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}
