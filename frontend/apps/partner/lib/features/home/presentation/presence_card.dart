import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/home/presentation/presence_cubit.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The online switch, or the "requests paused" notice when a document must
/// be renewed first (M15b).
class PresenceCard extends StatelessWidget {
  /// Creates the card.
  const PresenceCard({required this.state, required this.paused, super.key});

  /// The switch state.
  final OnlineState state;

  /// Requests are paused by an expired document.
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (paused) return _paused(context);
    return PaoCard(
      highlighted: state.online,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: state.online,
            onChanged: state.busy
                ? null
                : (_) => context.read<PresenceCubit>().toggle(),
            title: Text(state.online ? t.homeOnline : t.homeOffline),
            subtitle: Text(state.online ? t.homeOnlineBody : t.homeOfflineBody),
          ),
          if (state.locationOff)
            Text(
              t.homeLocationOff,
              style: const TextStyle(color: PaoColors.warning),
            ),
          if (state.failure != null)
            Text(
              context.failureText(state.failure)!,
              style: const TextStyle(color: PaoColors.danger),
            ),
        ],
      ),
    );
  }

  Widget _paused(BuildContext context) => PaoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t.homePausedTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: PaoSpace.sm),
        Text(context.t.homePausedBody),
        const SizedBox(height: PaoSpace.md),
        PaoButton(
          label: context.t.homeRenew,
          onPressed: () => context.push(Routes.profilePage('documents')),
        ),
      ],
    ),
  );
}
