import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/date_field.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// M05: name as on the NID, date of birth, gender and addresses.
class PersonalStep extends StatefulWidget {
  /// Creates the step; [today] bounds the date of birth.
  const PersonalStep({required this.today, super.key});

  /// The current date.
  final DateTime today;

  @override
  State<PersonalStep> createState() => _PersonalStepState();
}

class _PersonalStepState extends State<PersonalStep> {
  final _name = TextEditingController();
  final _present = TextEditingController();
  final _permanent = TextEditingController();
  DateTime? _birth;
  Gender? _gender;
  bool _checked = false;

  @override
  void dispose() {
    _name.dispose();
    _present.dispose();
    _permanent.dispose();
    super.dispose();
  }

  bool get _nameOk => _name.text.trim().length >= 3;
  bool get _birthOk => _birth != null && isAdult(_birth!, widget.today);
  bool _addressOk(TextEditingController c) => c.text.trim().length >= 5;

  Future<void> _save() async {
    setState(() => _checked = true);
    final ok =
        _nameOk &&
        _birthOk &&
        _gender != null &&
        _addressOk(_present) &&
        _addressOk(_permanent);
    if (!ok) return;
    await context.read<EnrolmentCubit>().save(
      PersonalDetails(
        fullName: _name.text.trim(),
        dateOfBirth: _birth!,
        gender: _gender!,
        presentAddress: _present.text.trim(),
        permanentAddress: _permanent.text.trim(),
      ),
    );
  }

  String? _error(bool ok, String message) => _checked && !ok ? message : null;

  @override
  Widget build(BuildContext context) => StepBody(
    onNext: _save,
    children: [..._identity(context.t), ..._addresses(context.t)],
  );

  List<Widget> _identity(PartnerL10n t) => [
    PaoTextField(
      label: t.enrolNameLabel,
      controller: _name,
      error: _error(_nameOk, t.enrolNameError),
    ),
    const SizedBox(height: PaoSpace.lg),
    DateField(
      label: t.enrolDobLabel,
      value: _birth,
      first: DateTime(widget.today.year - 80),
      last: widget.today,
      onChanged: (d) => setState(() => _birth = d),
      error: _error(_birthOk, t.enrolDobError),
    ),
    const SizedBox(height: PaoSpace.lg),
    Text(t.enrolGenderLabel),
    const SizedBox(height: PaoSpace.sm),
    PaoSegmented<Gender?>(
      segments: {
        Gender.female: t.enrolGenderFemale,
        Gender.male: t.enrolGenderMale,
        Gender.other: t.enrolGenderOther,
      },
      selected: _gender,
      onChanged: (g) => setState(() => _gender = g),
    ),
    if (_error(_gender != null, t.enrolGenderError) case final e?)
      Text(e, style: const TextStyle(color: PaoColors.danger)),
  ];

  List<Widget> _addresses(PartnerL10n t) => [
    const SizedBox(height: PaoSpace.lg),
    PaoTextField(
      label: t.enrolPresentAddress,
      controller: _present,
      maxLines: 2,
      error: _error(_addressOk(_present), t.enrolAddressError),
    ),
    const SizedBox(height: PaoSpace.lg),
    PaoTextField(
      label: t.enrolPermanentAddress,
      controller: _permanent,
      maxLines: 2,
      error: _error(_addressOk(_permanent), t.enrolAddressError),
    ),
  ];
}
