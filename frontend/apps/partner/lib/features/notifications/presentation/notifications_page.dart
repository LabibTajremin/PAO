import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Notification, NotificationList;
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/job/presentation/job_text.dart';
import 'package:pao_partner/features/notifications/data/api_notifications_repository.dart';
import 'package:pao_partner/features/notifications/domain/push_route.dart';
import 'package:pao_partner/features/notifications/presentation/notifications_cubit.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The notification inbox; a tap marks it read and opens its screen.
class NotificationsPage extends StatelessWidget {
  /// Creates the page.
  const NotificationsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        NotificationsCubit(ApiNotificationsRepository(services.api))
          ..load().ignore(),
    child: BlocBuilder<NotificationsCubit, ViewState<NotificationList>>(
      builder: _inbox,
    ),
  );

  Widget _inbox(BuildContext context, ViewState<NotificationList> s) {
    final cubit = context.read<NotificationsCubit>();
    final unread = s is ViewData<NotificationList> && s.data.unreadCount > 0;
    return Scaffold(
      appBar: PaoAppBar(
        title: context.common.navNotifications,
        actions: [
          if (unread)
            TextButton(
              onPressed: cubit.readAll,
              child: Text(context.t.notifReadAll),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ViewStateView<NotificationList>(
          state: s,
          onRetry: cubit.load,
          isEmpty: (d) => d.items.isEmpty,
          empty: PaoEmptyState(
            icon: Icons.notifications_none_outlined,
            title: context.t.notifEmpty,
            message: context.t.notifEmptyBody,
          ),
          builder: (context, d) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [for (final n in d.items) _row(context, n)],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Notification n) => PaoListRow(
    leading: Icon(
      n.read ? Icons.notifications_none_outlined : Icons.notifications_active,
      color: n.read ? PaoColors.textTertiary : context.pao.accent.primary,
    ),
    title: n.title,
    subtitle: [
      n.body,
      formatDhaka(n.createdAt, pattern: 'd MMM, h:mm a', locale: context.lang),
    ].join('\n'),
    onTap: () => _open(context, n),
  );

  Future<void> _open(BuildContext context, Notification n) async {
    final route = pushRoute({'bookingId': n.bookingId, 'type': n.type});
    if (!n.read) await context.read<NotificationsCubit>().markRead(n.id);
    if (route != Routes.notifications && context.mounted) {
      await context.push(route);
    }
  }
}
