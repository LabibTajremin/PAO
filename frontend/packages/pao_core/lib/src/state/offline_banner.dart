import 'package:flutter/material.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Puts the offline notice (C36) above [child] while the device has no network.
class OfflineBanner extends StatelessWidget {
  /// Creates the wrapper.
  const OfflineBanner({required this.watcher, required this.child, super.key});

  /// Network state.
  final ValueNotifier<bool> watcher;

  /// The app content.
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: watcher,
    builder: (context, online, _) => Column(
      children: [
        if (!online)
          SafeArea(
            bottom: false,
            child: PaoBanner(message: PaoL10n.of(context).offlineBanner),
          ),
        Expanded(child: child),
      ],
    ),
  );
}
