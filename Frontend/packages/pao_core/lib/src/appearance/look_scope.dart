import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pao_core/src/appearance/app_look.dart';
import 'package:pao_core/src/appearance/look_artwork.dart';
import 'package:pao_core/src/failure.dart';
import 'package:pao_ui/pao_ui.dart';

/// Hands the app's look to shared views, such as the error states, that are
/// built far from `AppServices`.
class LookScope extends InheritedWidget {
  /// Provides [look] to [child].
  const LookScope({required this.look, required super.child, super.key});

  /// The app's current look.
  final ValueListenable<AppLook> look;

  /// The look above [context], if an app provided one.
  static ValueListenable<AppLook>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LookScope>()?.look;

  @override
  bool updateShouldNotify(LookScope oldWidget) => look != oldWidget.look;
}

/// The illustration of [slot] from the nearest [LookScope], or the bundled
/// seed where there is none.
class ScopedArtwork extends StatelessWidget {
  /// Creates the illustration.
  const ScopedArtwork(this.slot, {super.key});

  /// The slot key.
  final String slot;

  @override
  Widget build(BuildContext context) {
    final look = LookScope.maybeOf(context);
    return look == null ? PaoArtwork(slot) : LookArtwork(look, slot);
  }
}

/// The picture for a failure: the offline scene when the device could not
/// reach the API, else none (the error icon).
Widget? failureArtwork(AppFailure? failure) =>
    failure is NetworkFailure ? const ScopedArtwork(offlineSlot) : null;

/// The slot of the offline scene.
const offlineSlot = 'offline';
