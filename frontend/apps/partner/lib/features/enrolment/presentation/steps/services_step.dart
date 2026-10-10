import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment_repository.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The API accepts up to five services per provider.
const _maxServices = 5;

/// M06: services offered and experience.
class ServicesStep extends StatelessWidget {
  /// Creates the step.
  const ServicesStep({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = LoadCubit<List<ServiceOption>>(
        context.read<EnrolmentRepository>().serviceOptions,
      );
      unawaited(cubit.load());
      return cubit;
    },
    child:
        BlocBuilder<
          LoadCubit<List<ServiceOption>>,
          ViewState<List<ServiceOption>>
        >(
          builder: (context, state) => ViewStateView(
            state: state,
            onRetry: context.read<LoadCubit<List<ServiceOption>>>().load,
            isEmpty: (options) => options.isEmpty,
            empty: PaoEmptyState(title: context.t.enrolServicesEmpty),
            builder: (_, options) => _ServicesForm(options: options),
          ),
        ),
  );
}

class _ServicesForm extends StatefulWidget {
  const _ServicesForm({required this.options});

  final List<ServiceOption> options;

  @override
  State<_ServicesForm> createState() => _ServicesFormState();
}

class _ServicesFormState extends State<_ServicesForm> {
  final _chosen = <String>{};
  var _years = 1;
  var _checked = false;

  void _toggle(String id) => setState(() {
    if (!_chosen.remove(id) && _chosen.length < _maxServices) _chosen.add(id);
  });

  Future<void> _save() async {
    setState(() => _checked = true);
    if (_chosen.isEmpty) return;
    await context.read<EnrolmentCubit>().save(
      ServiceChoice(serviceIds: _chosen.toList(), experienceYears: _years),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final language = Localizations.localeOf(context).languageCode;
    return StepBody(
      onNext: _save,
      children: [
        Text(t.enrolServicesHint),
        const SizedBox(height: PaoSpace.md),
        Wrap(
          spacing: PaoSpace.sm,
          runSpacing: PaoSpace.sm,
          children: [
            for (final o in widget.options)
              PaoChip(
                label: o.name(language),
                selected: _chosen.contains(o.id),
                onTap: () => _toggle(o.id),
              ),
          ],
        ),
        if (_checked && _chosen.isEmpty)
          Text(
            t.enrolServicesError,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.xl),
        Text(t.enrolExperience),
        const SizedBox(height: PaoSpace.sm),
        PaoStepper(
          value: _years,
          max: 60,
          onChanged: (v) => setState(() => _years = v),
        ),
      ],
    );
  }
}
