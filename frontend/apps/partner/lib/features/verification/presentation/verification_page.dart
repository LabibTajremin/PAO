import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/verification/data/api_verification_repository.dart';
import 'package:pao_partner/features/verification/domain/verification.dart';
import 'package:pao_partner/features/verification/presentation/verification_body.dart';
import 'package:pao_partner/features/verification/presentation/verification_cubit.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Verification status, rejection reasons and re-upload (M14); the screen
/// the gate keeps providers on until Level 1.
class VerificationPage extends StatelessWidget {
  /// Creates the page.
  const VerificationPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = VerificationCubit(
        ApiVerificationRepository(services.api),
        reloadGate: services.gate.load,
      );
      unawaited(cubit.load());
      return cubit;
    },
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.verifTitle),
      body: BlocBuilder<VerificationCubit, ViewState<VerificationSummary>>(
        builder: (context, state) {
          final cubit = context.read<VerificationCubit>();
          return ViewStateView(
            state: state,
            onRetry: cubit.load,
            builder: (_, summary) => RefreshIndicator(
              onRefresh: cubit.pull,
              child: VerificationBody(summary: summary, gate: services.gate),
            ),
          );
        },
      ),
    ),
  );
}
