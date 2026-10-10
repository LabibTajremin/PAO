import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Notification;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/notifications/data/api_notifications_repository.dart';
import 'package:pao_customer/features/notifications/domain/push_route.dart';
import 'package:pao_customer/features/notifications/presentation/notifications_cubit.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The notification inbox (C21, empty C59); a tap marks it read and opens
/// the booking it is about.
class NotificationsPage extends StatefulWidget {
  /// Creates the page.
  const NotificationsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsCubit _cubit = NotificationsCubit(
    ApiNotificationsRepository(widget.services.api),
  ).loading();

  @override
  void dispose() {
    _cubit.close().ignore();
    super.dispose();
  }

  Future<void> _readAll() async {
    final failure = await _cubit.readAll();
    if (failure == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.failureText(failure)!)));
  }

  Future<void> _open(Notification n) async {
    if (!n.read) await _cubit.markRead(n.id);
    final route = pushRoute({'bookingId': n.bookingId, 'type': n.type});
    if (route != Routes.notifications && mounted) await context.push(route);
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider<PagedCubit<Notification>>.value(
        value: _cubit,
        child: Scaffold(
          appBar: PaoAppBar(
            title: context.common.navNotifications,
            actions: [
              BlocBuilder<PagedCubit<Notification>, PagedState<Notification>>(
                builder: (context, _) => _cubit.hasUnread
                    ? TextButton(
                        onPressed: _readAll,
                        child: Text(context.t.notifReadAll),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _cubit.load,
            child: PagedView<Notification>(
              itemBuilder: (_, n) => _Row(note: n, onTap: () => _open(n)),
              empty: PaoEmptyState(
                icon: Icons.notifications_none_outlined,
                title: context.t.notifEmpty,
                message: context.t.notifEmptyBody,
              ),
            ),
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.note, required this.onTap});

  final Notification note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !note.read;
    return Semantics(
      label: unread ? context.t.notifUnread : null,
      child: PaoListRow(
        leading: Icon(
          unread ? Icons.notifications_active : Icons.notifications_none,
          color: unread ? context.pao.accent.primary : PaoColors.textTertiary,
        ),
        title: note.title,
        subtitle:
            '${note.body}\n${context.when(note.createdAt, 'd MMM, h:mm a')}',
        onTap: onTap,
      ),
    );
  }
}
