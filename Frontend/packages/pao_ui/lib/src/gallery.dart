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
import 'package:pao_ui/src/widgets/stitch.dart';
import 'package:pao_ui/src/widgets/text_field.dart';

/// Every component on one page, re-themed by the accent and mode pickers; run
/// it with `flutter run -t example/main.dart` inside `pao_ui`.
class PaoGalleryPage extends StatefulWidget {
  /// Creates the gallery.
  const PaoGalleryPage({super.key});

  @override
  State<PaoGalleryPage> createState() => _PaoGalleryPageState();
}

class _PaoGalleryPageState extends State<PaoGalleryPage> {
  AccentPreset _accent = AccentPreset.midnight;
  bool _dark = false;
  int _qty = 1;

  Widget _pickers() => Wrap(
    spacing: PaoSpace.sm,
    runSpacing: PaoSpace.sm,
    children: [
      for (final a in AccentPreset.values)
        PaoChip(
          label: a.name,
          selected: a == _accent,
          onTap: () => setState(() => _accent = a),
        ),
      PaoChip(
        label: 'dark',
        selected: _dark,
        onTap: () => setState(() => _dark = !_dark),
      ),
    ],
  );

  List<Widget> _actions() => [
    for (final v in PaoButtonVariant.values)
      Padding(
        padding: const EdgeInsets.only(bottom: PaoSpace.sm),
        child: PaoButton(label: v.name, onPressed: () {}, variant: v),
      ),
    const SizedBox(height: PaoSpace.sm),
    const PaoTextField(label: 'Phone', prefix: '+880', hint: '1XXXXXXXXX'),
  ];

  List<Widget> _display(TextTheme text) => [
    const Wrap(
      spacing: PaoSpace.sm,
      runSpacing: PaoSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PaoAvatar(name: 'Rahim Uddin'),
        PaoIconTile(icon: Icons.bolt),
        PaoBadge(label: 'Verified', tone: PaoTone.success),
        PaoBadge(label: 'Pending', tone: PaoTone.warning),
      ],
    ),
    const SizedBox(height: PaoSpace.lg),
    PaoCard(
      padding: EdgeInsets.zero,
      child: PaoListRow(title: 'Fan installation', onTap: () {}),
    ),
    const SizedBox(height: PaoSpace.md),
    PaoCard(
      highlighted: true,
      child: Row(
        children: [
          Expanded(child: Text('AC servicing', style: text.titleMedium)),
          PaoMoneyText(113000, style: text.titleMedium),
        ],
      ),
    ),
  ];

  List<Widget> _flow() => [
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
    const PaoRatingStars(rating: 4.5, semanticLabel: '4.5 out of 5 stars'),
  ];

  List<Widget> _feedback() => const [
    PaoBanner(message: 'You are offline.'),
    SizedBox(height: PaoSpace.lg),
    PaoMapFrame(label: 'Banani', height: 120),
    SizedBox(height: PaoSpace.lg),
    PaoSkeletonList(count: 1),
    SizedBox(height: 280, child: PaoEmptyState(title: 'No bookings yet')),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = _dark
        ? PaoTheme.dark(accent: _accent)
        : PaoTheme.light(accent: _accent);
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: const Text('PAO components')),
        body: ListView(
          padding: const EdgeInsets.all(PaoSpace.xl),
          children: [
            Text('Nakshi', style: theme.textTheme.displaySmall),
            Text('পাও — ঘরের সেবা', style: theme.textTheme.bodyMedium),
            const PaoStitchDivider(),
            _pickers(),
            const PaoStitchDivider(),
            ..._actions(),
            const PaoStitchDivider(),
            ..._display(theme.textTheme),
            const PaoStitchDivider(),
            ..._flow(),
            const PaoStitchDivider(),
            ..._feedback(),
          ],
        ),
      ),
    );
  }
}
