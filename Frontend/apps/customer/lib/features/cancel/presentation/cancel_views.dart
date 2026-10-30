import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking;
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/booking/presentation/waiting_views.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_cubit.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_page.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Cancelled (C53), blocked after the start (C54) or no longer active.
class CancelResult extends StatelessWidget {
  /// Creates the view.
  const CancelResult({required this.outcome, required this.booking, super.key});

  /// How cancelling ended.
  final CancelOutcome outcome;

  /// The booking.
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final home = PaoButton(
      label: t.bookingBackHome,
      variant: PaoButtonVariant.ghost,
      onPressed: () => context.go(Routes.home),
    );
    return switch (outcome) {
      CancelOutcome.cancelled => PaoMessageState(
        icon: Icons.event_busy_outlined,
        title: t.cancelDoneTitle,
        message: t.cancelDoneBody,
        action: _actions([
          PaoButton(
            label: t.cancelBookAgain,
            onPressed: () => context.go(providersAgain(booking)),
          ),
          home,
        ]),
      ),
      CancelOutcome.blocked => _blocked(context),
      CancelOutcome.closed => PaoMessageState(
        icon: Icons.info_outline,
        title: t.cancelClosedTitle,
        action: home,
      ),
    };
  }

  Widget _actions(List<Widget> buttons) => Column(children: buttons);

  Widget _blocked(BuildContext context) => PaoMessageState(
    icon: Icons.lock_clock_outlined,
    title: context.t.cancelBlockedTitle,
    message: context.t.cancelBlockedBody,
    action: _actions([
      PaoButton(
        label: context.t.liveReport,
        onPressed: () => context.go(Routes.booking(booking.id, 'report')),
      ),
      PaoButton(
        label: context.common.actionBack,
        variant: PaoButtonVariant.ghost,
        onPressed: () => leaveCancel(context, booking.id),
      ),
    ]),
  );
}
