import 'package:flutter/material.dart';
import 'package:pao_ui/src/theme.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/widgets/avatar.dart';
import 'package:pao_ui/src/widgets/badge.dart';
import 'package:pao_ui/src/widgets/banner.dart';
import 'package:pao_ui/src/widgets/button.dart';
import 'package:pao_ui/src/widgets/card.dart';
import 'package:pao_ui/src/widgets/chip.dart';
import 'package:pao_ui/src/widgets/icon_tile.dart';
import 'package:pao_ui/src/widgets/list_row.dart';
import 'package:pao_ui/src/widgets/map_frame.dart';
import 'package:pao_ui/src/widgets/money_text.dart';
import 'package:pao_ui/src/widgets/rating_stars.dart';
import 'package:pao_ui/src/widgets/segmented.dart';
import 'package:pao_ui/src/widgets/skeleton.dart';
import 'package:pao_ui/src/widgets/states.dart';
import 'package:pao_ui/src/widgets/status_stepper.dart';
import 'package:pao_ui/src/widgets/stepper.dart';
import 'package:pao_ui/src/widgets/text_field.dart';

/// Every component on one page, re-themed by the accent picker; run it with
/// `flutter run -t example/main.dart` inside `pao_ui`.
class PaoGalleryPage extends StatefulWidget {
  /// Creates the gallery.
  const PaoGalleryPage({super.key});

  @override
  State<PaoGalleryPage> createState() => _PaoGalleryPageState();
}

class _PaoGalleryPageState extends State<PaoGalleryPage> {
  AccentPreset _accent = AccentPreset.midnight;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PaoTheme.light(accent: _accent),
      child: Scaffold(
        appBar: AppBar(title: const Text('PAO components')),
        body: ListView(
          padding: const EdgeInsets.all(PaoSpace.lg),
          children: [
            Wrap(
              spacing: PaoSpace.sm,
              runSpacing: PaoSpace.sm,
              children: [
                for (final a in AccentPreset.values)
                  PaoChip(
                    label: a.name,
                    selected: a == _accent,
                    onTap: () => setState(() => _accent = a),
                  ),
              ],
            ),
            const SizedBox(height: PaoSpace.lg),
            for (final v in PaoButtonVariant.values)
              Padding(
                padding: const EdgeInsets.only(bottom: PaoSpace.sm),
                child: PaoButton(label: v.name, onPressed: () {}, variant: v),
              ),
            const PaoTextField(
              label: 'Phone',
              prefix: '+880',
              hint: '1XXXXXXXXX',
            ),
            const SizedBox(height: PaoSpace.lg),
            const Row(
              children: [
                PaoAvatar(name: 'Rahim Uddin'),
                SizedBox(width: PaoSpace.sm),
                PaoIconTile(icon: Icons.bolt),
                SizedBox(width: PaoSpace.sm),
                PaoBadge(label: 'Verified', tone: PaoTone.success),
              ],
            ),
            const SizedBox(height: PaoSpace.lg),
            PaoCard(
              child: PaoListRow(title: 'Fan installation', onTap: () {}),
            ),
            const SizedBox(height: PaoSpace.lg),
            PaoSegmented(
              segments: const {0: 'Upcoming', 1: 'Past'},
              selected: 0,
              onChanged: (_) {},
            ),
            PaoStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
            const PaoStatusStepper(
              steps: ['Accepted', 'On the way', 'Arrived'],
              current: 1,
            ),
            const PaoMoneyText(113000),
            const PaoRatingStars(
              rating: 4.5,
              semanticLabel: '4.5 out of 5 stars',
            ),
            const PaoBanner(message: 'You are offline.'),
            const SizedBox(height: PaoSpace.lg),
            const PaoMapFrame(label: 'Banani', height: 120),
            const SizedBox(height: PaoSpace.lg),
            const PaoSkeletonList(count: 1),
            const SizedBox(
              height: 240,
              child: PaoEmptyState(title: 'No bookings yet'),
            ),
          ],
        ),
      ),
    );
  }
}
