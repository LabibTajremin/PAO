import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/profile/data/api_profile_repository.dart';
import 'package:pao_partner/features/profile/presentation/language_cubit.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Bangla or English (M34).
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
    final repo = ApiProfileRepository(_services.api);
    _cubit = LanguageCubit(
      keep: (code) => _services.prefs.setString(Prefs.languageKey, code),
      upload: (code) => repo.update(
        ProviderProfileUpdate(
          language: Language.values.firstWhere((l) => l.value == code),
        ),
      ),
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
      appBar: PaoAppBar(title: context.t.profLanguageTitle),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        children: [
          Text(context.t.profLanguageBody),
          const SizedBox(height: PaoSpace.xl),
          PaoLanguageSwitch(controller: _services.locale),
          const SizedBox(height: PaoSpace.lg),
          BlocBuilder<LanguageCubit, AppFailure?>(
            builder: (context, failure) => failure == null
                ? const SizedBox.shrink()
                : Text(
                    context.t.profLanguageNotSynced(
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
