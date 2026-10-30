import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// One onboarding slide: an icon, a title and a short explanation.
class OnboardingSlide extends StatelessWidget {
  /// Creates the slide.
  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  /// Illustration.
  final IconData icon;

  /// Heading.
  final String title;

  /// Explanation.
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(PaoSpace.xxl),
      child: Column(
        children: [
          const SizedBox(height: PaoSpace.xxxl),
          PaoIconTile(icon: icon, size: 96),
          const SizedBox(height: PaoSpace.xxl),
          Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: PaoSpace.md),
          Text(
            body,
            style: text.bodyLarge!.copyWith(color: PaoColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
