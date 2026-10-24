import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/billing/data/api_billing_repository.dart';
import 'package:pao_partner/features/billing/presentation/billing_labels.dart';
import 'package:pao_partner/features/billing/presentation/pay_cubit.dart';
import 'package:pao_partner/shared/job_text.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Reports a payment of the due: amount, method and reference (ADR-0035 §4).
class PayPage extends StatelessWidget {
  /// Creates the page.
  const PayPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PayCubit(ApiBillingRepository(services.api)),
    child: BlocListener<PayCubit, PayState>(
      listenWhen: (p, s) => !p.sent && s.sent,
      listener: (context, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.t.paySent)));
        context.leave(Routes.billing);
      },
      child: Scaffold(
        appBar: PaoAppBar(title: context.t.payTitle),
        body: const _PayForm(),
      ),
    ),
  );
}

class _PayForm extends StatefulWidget {
  const _PayForm();

  @override
  State<_PayForm> createState() => _PayFormState();
}

class _PayFormState extends State<_PayForm> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PayCubit>();
    final s = context.watch<PayCubit>().state;
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        Text(t.payIntro),
        const SizedBox(height: PaoSpace.xl),
        PaoTextField(
          label: t.payAmount,
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
          ],
          error: s.badAmount ? t.payAmountInvalid : null,
        ),
        const SizedBox(height: PaoSpace.xl),
        Text(t.payMethod, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: PaoSpace.sm),
        Wrap(
          spacing: PaoSpace.sm,
          runSpacing: PaoSpace.sm,
          children: [
            for (final MapEntry(key: method, value: label) in paymentMethods(
              t,
            ).entries)
              PaoChip(
                label: label,
                selected: s.method == method,
                onTap: () => cubit.choose(method),
              ),
          ],
        ),
        _error(s.missingMethod ? t.payMethodMissing : null),
        const SizedBox(height: PaoSpace.xl),
        PaoTextField(
          label: t.payReference,
          controller: _reference,
          hint: t.payReferenceHint,
          error: s.badReference ? t.payReferenceInvalid : null,
        ),
        _error(context.failureText(s.failure)),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: t.paySubmit,
          loading: s.sending,
          onPressed: () => cubit.submit(_amount.text, _reference.text),
        ),
      ],
    );
  }

  Widget _error(String? message) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: PaoSpace.sm),
          child: Text(message, style: const TextStyle(color: PaoColors.danger)),
        );
}
