import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/widgets/stitch.dart';

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

/// The bottom navigation bar; the active item is marked by the accent and a
/// kantha stitch under its icon.
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
    final c = context.pao;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.action : c.inkFaint,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => Theme.of(context).textTheme.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected) ? c.action : c.inkFaint,
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.hairline)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onSelected,
          height: 64 + PaoSpace.sm,
          destinations: [for (final item in items) _destination(item)],
        ),
      ),
    );
  }

  NavigationDestination _destination(PaoNavItem item) {
    final icon = Badge(isLabelVisible: item.badge, child: Icon(item.icon));
    return NavigationDestination(
      icon: icon,
      selectedIcon: Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          const Positioned(left: 2, right: 2, bottom: -7, child: PaoStitch()),
        ],
      ),
      label: item.label,
    );
  }
}
