import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_customer/features/live/data/secure_screen.dart';
import 'package:pao_customer/features/live/presentation/start_code_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The start code, large, with screenshots blocked while it is visible
/// (02-architecture.md, mobile security).
class StartCodeCard extends StatefulWidget {
  /// Creates the card.
  const StartCodeCard({this.secure = const SecureScreen(), super.key});

  /// Screenshot blocking.
  final SecureScreen secure;

  @override
  State<StartCodeCard> createState() => _StartCodeCardState();
}

class _StartCodeCardState extends State<StartCodeCard> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.secure.protect(on: true));
  }

  @override
  void dispose() {
    unawaited(widget.secure.protect(on: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = context.watch<StartCodeCubit>().state;
    final code = s.code;
    final text = Theme.of(context).textTheme;
    return PaoCard(
      highlighted: true,
      child: Column(
        children: [
          Text(t.liveCodeTitle, style: text.titleSmall),
          const SizedBox(height: PaoSpace.sm),
          if (code != null)
            Semantics(
              label: t.liveCodeSemantics(code.split('').join(' ')),
              child: ExcludeSemantics(
                child: Text(
                  code,
                  style: text.displaySmall!.copyWith(letterSpacing: 12),
                ),
              ),
            )
          else ...[
            Text(context.failureText(s.failure) ?? context.common.loading),
            TextButton(
              onPressed: context.read<StartCodeCubit>().load,
              child: Text(context.common.actionRetry),
            ),
          ],
          const SizedBox(height: PaoSpace.sm),
          Text(
            t.liveCodeHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PaoColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
