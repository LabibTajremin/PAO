import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pao_core/src/appearance/app_look.dart';
import 'package:pao_ui/pao_ui.dart';

/// The illustration of [slot]: the admin's cached image from [look], else the
/// seed the app bundles (ADR-0040).
class LookArtwork extends StatelessWidget {
  /// Creates the illustration.
  const LookArtwork(this.look, this.slot, {super.key});

  /// The app's current look, from `AppLookService.look`.
  final ValueListenable<AppLook> look;

  /// The slot key.
  final String slot;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppLook>(
    valueListenable: look,
    builder: (context, value, _) {
      final image = value.artwork[slot];
      return PaoArtwork(slot, image: image?.bytes, isSvg: image?.isSvg ?? true);
    },
  );
}
