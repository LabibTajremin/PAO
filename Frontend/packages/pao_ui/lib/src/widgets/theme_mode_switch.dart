import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pao_ui/src/widgets/segmented.dart';

/// System / light / dark toggle; the app supplies the [labels] in its language
/// and saves the choice in [onChanged].
class PaoThemeModeSwitch extends StatelessWidget {
  /// Creates the switch.
  const PaoThemeModeSwitch({
    required this.mode,
    required this.labels,
    required this.onChanged,
    super.key,
  });

  /// The current appearance.
  final ValueListenable<ThemeMode> mode;

  /// The name of each mode.
  final Map<ThemeMode, String> labels;

  /// Called with the chosen mode.
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: mode,
    builder: (context, current, _) => PaoSegmented<ThemeMode>(
      segments: labels,
      selected: current,
      onChanged: onChanged,
    ),
  );
}
