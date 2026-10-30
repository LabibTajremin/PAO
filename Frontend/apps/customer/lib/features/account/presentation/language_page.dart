import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/account/presentation/language_cubit.dart';
import 'package:pao_customer/features/auth/data/api_profile_setup_repository.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Bangla or English (C26).
class LanguagePage extends StatefulWidget {
  /// Creates the page.
  const LanguagePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late final LanguageCubit _cubit;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    final repo = ApiProfileSetupRepository(
      _services.api,
      onSaved: _services.gate.saved,
    );
    _cubit = LanguageCubit(
      keep: (code) => _services.prefs.setString(Prefs.languageKey, code),
      upload: (code) async {
        // Without a loaded profile (offline at launch) there is no name to
        // send; the next profile save carries the language instead.
        final profile = _services.gate.profile;
        if (profile != null) {
          await repo.save(name: profile.name, language: code);
        }
      },
    );
    _services.locale.addListener(_changed);
  }

  void _changed() =>
      unawaited(_cubit.select(_services.locale.value.languageCode));

  @override
  void dispose() {
    _services.locale.removeListener(_changed);
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.accountLanguage),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        children: [
          Text(context.t.accountLanguageBody),
          const SizedBox(height: PaoSpace.xl),
          PaoLanguageSwitch(controller: _services.locale),
          const SizedBox(height: PaoSpace.lg),
          BlocBuilder<LanguageCubit, AppFailure?>(
            builder: (context, failure) => failure == null
                ? const SizedBox.shrink()
                : Text(
                    context.t.accountLanguageNotSynced(
                      context.failureText(failure)!,
                    ),
                    style: const TextStyle(color: PaoColors.danger),
                  ),
          ),
        ],
      ),
    ),
  );
}
