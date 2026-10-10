import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// A row of filters above a table that wraps on narrow screens; [search]
/// is called with the text when the admin presses enter.
class FilterBar extends StatelessWidget {
  /// Creates the bar.
  const FilterBar({
    this.search,
    this.searchHint,
    this.filters = const [],
    super.key,
  });

  /// Runs a text search; null hides the search box.
  final ValueChanged<String>? search;

  /// Placeholder in the search box.
  final String? searchHint;

  /// Dropdowns or chips that narrow the list.
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PaoSpace.lg),
    child: Wrap(
      spacing: PaoSpace.md,
      runSpacing: PaoSpace.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (search != null)
          SizedBox(
            width: 320,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: searchHint,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: search,
            ),
          ),
        ...filters,
      ],
    ),
  );
}
