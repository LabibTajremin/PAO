import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets('badges in every tone', (tester) async {
    await pumpPao(
      tester,
      Column(
        children: [
          for (final t in PaoTone.values) PaoBadge(label: t.name, tone: t),
          const PaoBadge(label: 'Level 2', icon: Icons.verified),
        ],
      ),
    );
    expect(find.text('danger'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('avatar shows initials and is labelled by name', (tester) async {
    await pumpPao(tester, const PaoAvatar(name: '  Rahim   Uddin Khan '));
    expect(find.text('RU'), findsOneWidget);
    expect(find.bySemanticsLabel('  Rahim   Uddin Khan '), findsOneWidget);
    expect(PaoAvatar.initials('রহিম'), 'র');
  });

  testWidgets('icon tile, cards and rows', (tester) async {
    var taps = 0;
    await pumpPao(
      tester,
      Column(
        children: [
          const PaoIconTile(icon: Icons.bolt),
          PaoCard(onTap: () => taps++, child: const Text('Plain')),
          const PaoCard(highlighted: true, child: Text('Tinted')),
          PaoListRow(
            title: 'Language',
            subtitle: 'English',
            leading: const Icon(Icons.language),
            onTap: () => taps++,
          ),
          const PaoListRow(title: 'Static', trailing: Text('v1')),
          const PaoListRow(title: 'Bare'),
        ],
      ),
    );
    await tester.tap(find.text('Plain'));
    await tester.tap(find.text('Language'));
    expect(taps, 2);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.text('v1'), findsOneWidget);
  });

  testWidgets('status stepper marks done, current and later steps', (
    tester,
  ) async {
    await pumpPao(
      tester,
      const PaoStatusStepper(steps: ['A', 'B', 'C'], current: 1),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('money follows the language', (tester) async {
    await pumpPao(tester, const PaoMoneyText(113000));
    expect(find.text('৳1,130'), findsOneWidget);
    await pumpPao(
      tester,
      const PaoMoneyText(113000),
      locale: const Locale('bn'),
    );
    expect(find.text('৳১,১৩০'), findsOneWidget);
  });

  testWidgets('rating stars draw halves and take input', (tester) async {
    await pumpPao(
      tester,
      const PaoRatingStars(rating: 3.5, semanticLabel: '3.5 of 5'),
    );
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('3.5 of 5'), findsOneWidget);
    int? picked;
    await pumpPao(
      tester,
      PaoRatingStars(
        rating: 0,
        semanticLabel: 'Rate',
        onChanged: (v) => picked = v,
      ),
    );
    await tester.tap(find.byTooltip('4'));
    expect(picked, 4);
  });

  testWidgets('map frame, banner and skeletons', (tester) async {
    await pumpPao(
      tester,
      const Column(
        children: [
          PaoMapFrame(label: 'Banani'),
          PaoMapFrame(label: 'x', child: Text('real map')),
          PaoBanner(message: 'Offline'),
          PaoSkeleton(width: 40),
          PaoSkeletonList(count: 2),
        ],
      ),
    );
    expect(find.text('Banani'), findsOneWidget);
    expect(find.text('real map'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(find.byType(PaoSkeleton), findsNWidgets(7));
  });
}
