import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// A centred card for the login screens.
class AuthFrame extends StatelessWidget {
  /// Creates the frame with a [title] above [children].
  const AuthFrame({required this.title, required this.children, super.key});

  /// Heading.
  final String title;

  /// Form content.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: PaoCard(
            padding: const EdgeInsets.all(PaoSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: PaoSpace.xl),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
