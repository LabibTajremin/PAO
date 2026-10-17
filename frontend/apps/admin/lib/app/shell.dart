import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/nav.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/auth/data/session_restore.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Width from which the menu stays open beside the content.
const wideLayout = 1024.0;

/// The console frame: a permission-filtered menu (a sidebar on wide screens,
/// a drawer below 1024 px) around the current screen.
class AdminShell extends StatelessWidget {
  /// Creates the shell around [child], highlighting [location].
  const AdminShell({
    required this.services,
    required this.location,
    required this.child,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Current path, to mark the active section.
  final String location;

  /// The current screen.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final menu = _Menu(services: services, location: location);
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= wideLayout
          ? Scaffold(
              body: Row(
                children: [
                  SizedBox(width: 240, child: menu),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              ),
            )
          : Scaffold(
              appBar: AppBar(title: Text(context.t.appTitle)),
              drawer: Drawer(child: menu),
              body: child,
            ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.services, required this.location});

  final AppServices services;
  final String location;

  @override
  Widget build(BuildContext context) {
    final visible = navEntries.where(
      (e) => services.permissions.canSee(e.screen),
    );
    return SafeArea(
      child: Column(
        children: [
          ListTile(
            title: Text(
              context.t.appTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final e in visible)
                  ListTile(
                    leading: Icon(e.icon),
                    title: Text(e.label(context.t)),
                    selected: location.startsWith(e.path),
                    onTap: () => context.go(e.path),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(PaoSpace.md),
            child: PaoLanguageSwitch(controller: services.locale),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(context.common.actionSignOut),
            onTap: () => signOut(services),
          ),
        ],
      ),
    );
  }
}
