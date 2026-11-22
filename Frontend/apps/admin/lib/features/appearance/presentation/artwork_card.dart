import 'package:flutter/material.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Why the backend refused an illustration, in words.
String? artworkFailureText(BuildContext context, AppFailure? failure) {
  final t = context.t;
  final details = failure is ApiFailure
      ? failure.details
      : const <String, Object?>{};
  return switch (details['reason']) {
    'artwork_wrong_size' => t.appearanceErrorSize('${details['expected']}'),
    'artwork_too_large' => t.appearanceErrorTooLarge,
    'artwork_unreadable' => t.iconErrorUnreadable,
    'artwork_opaque' => t.iconErrorOpaque,
    _ => context.failureText(failure),
  };
}

/// One slot: its size, the current image on light and dark with the safe
/// area marked, and upload and reset.
class ArtworkCard extends StatelessWidget {
  /// Creates the card.
  const ArtworkCard({
    required this.slot,
    required this.onUpload,
    required this.onReset,
    this.failure,
    super.key,
  });

  /// The slot.
  final ArtworkSlot slot;

  /// Asks for a file and uploads it; null without `settings:manage`.
  final VoidCallback? onUpload;

  /// Puts the original back; null without `settings:manage`.
  final VoidCallback? onReset;

  /// Why the last upload or reset failed.
  final AppFailure? failure;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final status = slot.replaced
        ? t.appearanceReplaced
        : slot.url == null
        ? t.appearanceBundled
        : t.appearanceOriginal;
    return SizedBox(
      width: 340,
      child: PaoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PaoSpace.sm,
          children: [
            Text(slot.key, style: Theme.of(context).textTheme.titleSmall),
            Text('${slot.width} × ${slot.height} px · $status'),
            Row(
              spacing: PaoSpace.sm,
              children: [
                Expanded(child: _Preview(slot, PaoTheme.light())),
                Expanded(child: _Preview(slot, PaoTheme.dark())),
              ],
            ),
            if (artworkFailureText(context, failure) case final text?)
              Text(text, style: TextStyle(color: context.pao.dangerInk)),
            Wrap(
              spacing: PaoSpace.sm,
              children: [
                OutlinedButton(
                  onPressed: onUpload,
                  child: Text(t.appearanceUpload),
                ),
                TextButton(
                  onPressed: slot.replaced ? onReset : null,
                  child: Text(t.appearanceReset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.slot, this.theme);

  final ArtworkSlot slot;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final seed = PaoArtwork(slot.key);
    final url = slot.url;
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: AspectRatio(
            aspectRatio: slot.width / slot.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url == null) seed else PaoRemoteImage(url, fallback: seed),
                // The safe area: the subject belongs inside the central 80%.
                FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.pao.action.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                // The sign-in sheet covers the hero's bottom 15%.
                if (slot.key.endsWith('signin.hero'))
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.15,
                      widthFactor: 1,
                      child: ColoredBox(
                        color: context.pao.card.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
