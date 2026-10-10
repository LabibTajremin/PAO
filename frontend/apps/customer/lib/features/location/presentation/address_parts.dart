import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/location/domain/places.dart';
import 'package:pao_customer/features/location/presentation/address_labels.dart';
import 'package:pao_customer/features/location/presentation/place_search_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The address search field and its suggestions.
class PlaceSearchBox extends StatelessWidget {
  /// Creates the box; [onPick] receives the chosen suggestion.
  const PlaceSearchBox({
    required this.controller,
    required this.onPick,
    super.key,
  });

  /// Holds the typed text.
  final TextEditingController controller;

  /// Called with the chosen place.
  final ValueChanged<Place> onPick;

  @override
  Widget build(BuildContext context) {
    final search = context.read<PlaceSearchCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaoTextField(
          label: context.t.locSearch,
          hint: context.t.locSearchHint,
          controller: controller,
          onChanged: search.query,
        ),
        BlocBuilder<PlaceSearchCubit, List<Place>>(
          builder: (_, places) => Column(
            children: [
              for (final p in places)
                PaoListRow(
                  title: p.title,
                  subtitle: p.area,
                  leading: const Icon(Icons.place_outlined),
                  onTap: () {
                    controller.clear();
                    search.clear();
                    onPick(p);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Whether PAO works at the pin (C35).
class CoverageNote extends StatelessWidget {
  /// Creates the note for [coverage].
  const CoverageNote({required this.coverage, super.key});

  /// The last check, if any.
  final ServiceAreaCheck? coverage;

  @override
  Widget build(BuildContext context) {
    final c = coverage;
    if (c == null) return const SizedBox.shrink();
    if (c.covered) {
      final area = c.areaName;
      return area == null
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.centerLeft,
              child: PaoBadge(
                label: context.t.locCovered(area),
                tone: PaoTone.success,
                icon: Icons.check_circle_outline,
              ),
            );
    }
    return PaoCard(
      highlighted: true,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.wrong_location_outlined),
        title: Text(context.t.locNotCoveredTitle),
        subtitle: Text(context.t.locNotCoveredBody),
      ),
    );
  }
}

/// Home, office or other.
class LabelChips extends StatelessWidget {
  /// Creates the chips with [selected] on.
  const LabelChips({required this.selected, required this.onChoose, super.key});

  /// The chosen label.
  final AddressLabel selected;

  /// Called with the tapped label.
  final ValueChanged<AddressLabel> onChoose;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.t.locLabel, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: PaoSpace.sm),
      Wrap(
        spacing: PaoSpace.sm,
        children: [
          for (final label in AddressLabel.values)
            PaoChip(
              label: addressLabelName(context.t, label),
              selected: label == selected,
              onTap: () => onChoose(label),
            ),
        ],
      ),
    ],
  );
}
