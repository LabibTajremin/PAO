import 'package:flutter/material.dart';
import 'package:pao_customer/features/providers/domain/providers_repository.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Asks for a new sort and filters (C40); null when dismissed.
Future<ProviderQuery?> showSortFilterSheet(
  BuildContext context,
  ProviderQuery current,
) => showPaoSheet<ProviderQuery>(
  context,
  title: context.t.provSortFilter,
  child: _SortFilter(initial: current),
);

class _SortFilter extends StatefulWidget {
  const _SortFilter({required this.initial});

  final ProviderQuery initial;

  @override
  State<_SortFilter> createState() => _SortFilterState();
}

class _SortFilterState extends State<_SortFilter> {
  late ProviderQuery _q = widget.initial;

  void _set({ProviderSort? sort, bool? topRated, bool? proOnly}) => setState(
    () => _q = ProviderQuery(
      sort: sort ?? _q.sort,
      topRated: topRated ?? _q.topRated,
      proOnly: proOnly ?? _q.proOnly,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final heading = Theme.of(context).textTheme.titleSmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaoSpace.md,
      children: [
        Text(t.provSort, style: heading),
        PaoSegmented<ProviderSort>(
          segments: {
            ProviderSort.distance: t.provSortDistance,
            ProviderSort.rating: t.provSortRating,
          },
          selected: _q.sort,
          onChanged: (sort) => _set(sort: sort),
        ),
        Text(t.provFilter, style: heading),
        Wrap(
          spacing: PaoSpace.sm,
          children: [
            PaoChip(
              label: t.provFilterTopRated,
              selected: _q.topRated,
              onTap: () => _set(topRated: !_q.topRated),
            ),
            PaoChip(
              label: t.provFilterPro,
              selected: _q.proOnly,
              onTap: () => _set(proOnly: !_q.proOnly),
            ),
          ],
        ),
        PaoButton(
          label: t.provApply,
          onPressed: () => Navigator.pop(context, _q),
        ),
      ],
    );
  }
}
