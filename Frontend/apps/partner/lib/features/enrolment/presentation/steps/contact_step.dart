import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/auth/domain/auth_repository.dart'
    show normalisePhone;
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// M12: emergency contact, confirmed by a code texted to their phone.
class ContactStep extends StatefulWidget {
  /// Creates the step.
  const ContactStep({super.key});

  @override
  State<ContactStep> createState() => _ContactStepState();
}

class _ContactStepState extends State<ContactStep> {
  final _name = TextEditingController();
  final _relation = TextEditingController();
  final _phone = TextEditingController();
  var _checked = false;

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
  }

  EmergencyContact? get _input {
    final phone = normalisePhone(_phone.text);
    final name = _name.text.trim();
    final relation = _relation.text.trim();
    if (phone == null || name.length < 2 || relation.length < 2) return null;
    return EmergencyContact(name: name, relation: relation, phone: phone);
  }

  Future<void> _send() async {
    setState(() => _checked = true);
    if (_input case final input?) {
      await context.read<EnrolmentCubit>().save(input);
    }
  }

  String? _error(bool bad, String message) => _checked && bad ? message : null;

  @override
  Widget build(BuildContext context) {
    final sent = context.select<EnrolmentCubit, bool>((c) => c.state.codeSent);
    final t = context.t;
    return sent
        ? _CodeEntry(phone: _input?.phone ?? '', onResend: _send)
        : StepBody(
            onNext: _send,
            nextLabel: t.enrolContactSendCode,
            children: [Text(t.enrolContactHint), ..._fields(t)],
          );
  }

  List<Widget> _fields(PartnerL10n t) => [
    const SizedBox(height: PaoSpace.lg),
    PaoTextField(
      label: t.enrolContactName,
      controller: _name,
      error: _error(_name.text.trim().length < 2, t.enrolContactNameError),
    ),
    const SizedBox(height: PaoSpace.lg),
    PaoTextField(
      label: t.enrolContactRelation,
      controller: _relation,
      error: _error(
        _relation.text.trim().length < 2,
        t.enrolContactRelationError,
      ),
    ),
    const SizedBox(height: PaoSpace.lg),
    PaoTextField(
      label: t.enrolContactPhone,
      controller: _phone,
      prefix: '+880',
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      error: _error(
        normalisePhone(_phone.text) == null,
        t.enrolContactPhoneError,
      ),
    ),
  ];
}

class _CodeEntry extends StatelessWidget {
  const _CodeEntry({required this.phone, required this.onResend});

  final String phone;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EnrolmentCubit>();
    final failure = context.select<EnrolmentCubit, AppFailure?>(
      (c) => c.state.failure,
    );
    return StepBody(
      onNext: null,
      showNext: false,
      extra: [
        PaoButton(
          label: context.t.enrolContactResend,
          variant: PaoButtonVariant.ghost,
          onPressed: onResend,
        ),
        PaoButton(
          label: context.t.enrolContactChange,
          variant: PaoButtonVariant.ghost,
          onPressed: cubit.editContact,
        ),
      ],
      children: [
        Text(context.t.enrolContactCodeSent(phone)),
        const SizedBox(height: PaoSpace.xl),
        PaoOtpInput(
          onCompleted: cubit.verifyCode,
          hasError: failure?.code == 'OTP_INVALID',
        ),
      ],
    );
  }
}
