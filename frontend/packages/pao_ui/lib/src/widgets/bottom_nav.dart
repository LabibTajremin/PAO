import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// One destination of [PaoBottomNav].
class PaoNavItem {
  /// Creates a destination.
  const PaoNavItem({
    required this.icon,
    required this.label,
    this.badge = false,
  });

  /// Icon.
  final IconData icon;

  /// Label under the icon.
  final String label;

  /// Shows a dot, e.g. for unread notifications.
  final bool badge;
}

/// The bottom navigation bar; the active item sits in an accent pill.
class PaoBottomNav extends StatelessWidget {
  /// Creates the bar.
  const PaoBottomNav({
    required this.items,
    required this.index,
    required this.onSelected,
    super.key,
  });

  /// Destinations.
  final List<PaoNavItem> items;

  /// Selected destination.
  final int index;

  /// Called with the tapped index.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: PaoColors.surface,
        indicatorColor: accent.soft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => Theme.of(context).textTheme.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected)
                ? accent.strong
                : PaoColors.textTertiary,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelected,
        height: 64 + PaoSpace.sm,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Badge(isLabelVisible: item.badge, child: Icon(item.icon)),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
