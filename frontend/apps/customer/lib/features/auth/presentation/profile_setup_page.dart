import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/auth/data/api_profile_setup_repository.dart';
import 'package:pao_customer/features/auth/presentation/profile_setup_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Profile set-up after the first sign-in (C05): name and an optional photo.
class ProfileSetupPage extends StatefulWidget {
  /// Creates the page.
  const ProfileSetupPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ProfileSetupCubit(
      ApiProfileSetupRepository(
        widget.services.api,
        onSaved: widget.services.gate.saved,
      ),
    ),
    child: BlocConsumer<ProfileSetupCubit, ProfileSetupState>(
      listenWhen: (_, s) => s.done,
      listener: (context, _) => context.go(Routes.location),
      builder: _form,
    ),
  );

  Widget _form(BuildContext context, ProfileSetupState s) {
    final cubit = context.read<ProfileSetupCubit>();
    final photo = s.photo;
    return Scaffold(
      appBar: PaoAppBar(title: context.t.authProfileTitle),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        children: [
          Text(context.t.authProfileBody),
          const SizedBox(height: PaoSpace.xxl),
          Center(
            child: PaoAvatar(
              name: _name.text,
              image: photo == null ? null : MemoryImage(photo),
              size: 96,
            ),
          ),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(context.t.authProfileAddPhoto),
              onPressed: () async =>
                  cubit.photo(await widget.services.photos.pick()),
            ),
          ),
          const SizedBox(height: PaoSpace.lg),
          PaoTextField(
            label: context.t.authProfileName,
            controller: _name,
            error: s.invalidName
                ? context.t.authProfileNameInvalid
                : context.failureText(s.failure),
          ),
          const SizedBox(height: PaoSpace.xxl),
          PaoButton(
            label: context.common.actionContinue,
            loading: s.saving,
            onPressed: () => cubit.save(
              _name.text,
              widget.services.locale.value.languageCode,
            ),
          ),
        ],
      ),
    );
  }
}
