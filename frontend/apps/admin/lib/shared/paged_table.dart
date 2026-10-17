import 'package:flutter/material.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// One column of a [PagedTable].
class AdminColumn<T> {
  /// Creates a column; [flex] shares the width with the other columns.
  const AdminColumn(this.label, this.cell, {this.flex = 1});

  /// Header text.
  final String label;

  /// Builds the cell for a row.
  final Widget Function(T row) cell;

  /// Share of the table width.
  final int flex;
}

/// A cursor-paged table over the nearest `PagedCubit<T>`: a header row, one
/// row per item (tap opens it), "load more", and the loading, empty and error
/// states of `PagedView`.
class PagedTable<T> extends StatelessWidget {
  /// Creates the table.
  const PagedTable({
    required this.columns,
    required this.empty,
    this.onOpen,
    this.header = const [],
    super.key,
  });

  /// Columns, left to right.
  final List<AdminColumn<T>> columns;

  /// Shown when there are no rows.
  final Widget empty;

  /// Opens a row, e.g. its detail screen.
  final void Function(T row)? onOpen;

  /// Widgets above the table, such as a filter bar.
  final List<Widget> header;

  @override
  Widget build(BuildContext context) => PagedView<T>(
    header: [
      ...header,
      _HeaderRow(columns: columns),
    ],
    empty: empty,
    itemBuilder: (context, row) => InkWell(
      onTap: onOpen == null ? null : () => onOpen!(row),
      child: _Cells(
        children: [
          for (final c in columns) Expanded(flex: c.flex, child: c.cell(row)),
        ],
      ),
    ),
  );
}

class _HeaderRow<T> extends StatelessWidget {
  const _HeaderRow({required this.columns});

  final List<AdminColumn<T>> columns;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!
        .copyWith(color: PaoColors.textSecondary);
    return _Cells(
      children: [
        for (final c in columns)
          Expanded(
            flex: c.flex,
            child: Text(c.label, style: style),
          ),
      ],
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: PaoColors.border)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: PaoSpace.md,
        horizontal: PaoSpace.sm,
      ),
      child: Row(spacing: PaoSpace.md, children: children),
    ),
  );
}
