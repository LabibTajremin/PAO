import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/enrolment/data/api_enrolment_repository.dart';
import 'package:pao_partner/features/enrolment/data/photo_capture.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment_repository.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_view.dart';
import 'package:pao_partner/features/enrolment/presentation/uploads_cubit.dart';

/// The resumable enrolment wizard (M05–M13), opened at [step].
class EnrolmentPage extends StatelessWidget {
  /// Creates the page.
  const EnrolmentPage({required this.services, required this.step, super.key});

  /// App services.
  final AppServices services;

  /// API name of the step to open; anything else resumes where the provider
  /// left off.
  final String step;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    // A new step in the route starts a fresh wizard on that step.
    key: ValueKey(step),
    providers: [
      RepositoryProvider<EnrolmentRepository>(
        create: (_) => ApiEnrolmentRepository(services.api),
      ),
      RepositoryProvider<LocationService>.value(value: services.location),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (c) {
            final cubit = EnrolmentCubit(
              c.read<EnrolmentRepository>(),
              onFinished: services.gate.load,
            );
            unawaited(cubit.load(step));
            return cubit;
          },
        ),
        BlocProvider(
          create: (c) => UploadsCubit(
            c.read<EnrolmentRepository>(),
            (mode) => capturePhoto(services.photos, mode),
          ),
        ),
      ],
      child: EnrolmentView(requested: step, now: services.now()),
    ),
  );
}
