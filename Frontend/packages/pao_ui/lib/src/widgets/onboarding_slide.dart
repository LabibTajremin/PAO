import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// One welcome slide (P24): the slot's [illustration] over a title and one
/// line, centred, scrolling when a large text size needs the room.
class PaoOnboardingSlide extends StatelessWidget {
  /// Creates the slide.
  const PaoOnboardingSlide({
    required this.illustration,
    required this.title,
    required this.body,
    super.key,
  });

  /// The slide's artwork, usually an `*.onboarding.N` slot.
  final Widget illustration;

  /// Heading.
  final String title;

  /// One line of explanation.
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: PaoSpace.xl),
      child: Column(
        children: [
          illustration,
          const SizedBox(height: PaoSpace.xl),
          Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: PaoSpace.sm),
          Text(
            body,
            style: text.bodyLarge!.copyWith(color: context.pao.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
