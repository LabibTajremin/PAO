import 'package:flutter/material.dart';

/// The PAO top bar: a title, an automatic back button and optional actions.
class PaoAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates the bar.
  const PaoAppBar({required this.title, this.actions = const [], super.key});

  /// Screen title.
  final String title;

  /// Buttons on the right.
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Semantics(header: true, child: Text(title)),
    actions: actions,
  );
}
