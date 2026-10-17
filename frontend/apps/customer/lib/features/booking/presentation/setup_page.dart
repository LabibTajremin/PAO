import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/booking/data/api_booking_repository.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';
import 'package:pao_customer/features/booking/presentation/setup_body.dart';
import 'package:pao_customer/features/booking/presentation/setup_cubit.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Booking set-up (C12 scheduled, C45 ASAP, C46 address): the chosen items,
/// timing, address, note and cash payment, then confirm.
class SetupPage extends StatelessWidget {
  /// Creates the page for [draft]; null when the link carried no service.
  const SetupPage({required this.services, required this.draft, super.key});

  /// App services.
  final AppServices services;

  /// What was chosen on the service and provider screens.
  final BookingDraft? draft;

  @override
  Widget build(BuildContext context) {
    final d = draft;
    final complete = d != null && d.providerId != null && d.items.isNotEmpty;
    return Scaffold(
      appBar: PaoAppBar(title: context.t.bookingSetupTitle),
      body: complete
          ? BlocProvider(
              create: (_) => SetupCubit(
                ApiBookingRepository(services.api),
                d,
                now: services.now,
              )..load().ignore(),
              child: _Setup(services: services),
            )
          : const NothingToBook(),
    );
  }
}

class _Setup extends StatelessWidget {
  const _Setup({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocConsumer<SetupCubit, SetupState>(
    listenWhen: (a, b) => a.booking == null && b.booking != null,
    listener: (context, s) =>
        context.go(Routes.booking(s.booking!.id, 'waiting')),
    builder: (context, s) {
      final cubit = context.read<SetupCubit>();
      return ViewStateView<BookingOptions>(
        state: s.view,
        onRetry: cubit.load,
        builder: (context, _) => cubit.lines.isEmpty
            ? const NothingToBook()
            : SetupBody(state: s, now: services.now),
      );
    },
  );
}

/// Shown when the link has no provider or items, or none can be booked.
class NothingToBook extends StatelessWidget {
  /// Creates the view.
  const NothingToBook({super.key});

  @override
  Widget build(BuildContext context) => PaoEmptyState(
    title: context.t.bookingNothingTitle,
    message: context.t.bookingNothingBody,
    action: PaoButton(
      label: context.t.bookingBrowse,
      expand: false,
      onPressed: () => context.go(Routes.services),
    ),
  );
}
