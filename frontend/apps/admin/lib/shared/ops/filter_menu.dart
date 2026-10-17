import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// A filter chip such as "Status: Active" that opens a menu of [options];
/// the first option is "any" and maps to null.
class FilterMenu<T> extends StatelessWidget {
  /// Creates the menu.
  const FilterMenu({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// What is filtered, e.g. "Status".
  final String label;

  /// Choices with their names; a null key means no filter.
  final Map<T?, String> options;

  /// The current choice.
  final T? value;

  /// Called with the new choice.
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final keys = options.keys.toList();
    return PopupMenuButton<int>(
      tooltip: label,
      onSelected: (i) => onChanged(keys[i]),
      itemBuilder: (_) => [
        for (final (i, key) in keys.indexed)
          CheckedPopupMenuItem(
            value: i,
            checked: key == value,
            child: Text(options[key]!),
          ),
      ],
      child: PaoChip(
        label: '$label: ${options[value]}',
        selected: value != null,
        onTap: null,
      ),
    );
  }
}
