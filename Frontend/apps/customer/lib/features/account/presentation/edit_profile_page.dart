import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/auth/data/api_profile_setup_repository.dart';
import 'package:pao_customer/features/auth/presentation/profile_setup_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_customer/shared/photos.dart';
import 'package:pao_ui/pao_ui.dart';

/// Edit profile (C23): name and photo; the language stays as chosen.
class EditProfilePage extends StatefulWidget {
  /// Creates the page.
  const EditProfilePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _name = TextEditingController(
    text: widget.services.gate.profile?.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _saved(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t.accountProfileSaved)));
    context.pop();
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
      listener: (context, _) => _saved(context),
      builder: _form,
    ),
  );

  void _save(ProfileSetupCubit cubit) {
    final services = widget.services;
    cubit
        .save(
          _name.text,
          services.gate.profile?.language.value ??
              services.locale.value.languageCode,
        )
        .ignore();
  }

  Widget _form(BuildContext context, ProfileSetupState s) {
    final cubit = context.read<ProfileSetupCubit>();
    return Scaffold(
      appBar: PaoAppBar(title: context.t.accountEditProfile),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.xl),
        children: [
          _Photo(
            name: _name.text,
            picked: s.photo,
            current: widget.services.gate.profile?.photoUrl,
            onPick: s.saving
                ? null
                : () async => cubit.photo(await widget.services.photos.pick()),
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
            label: context.common.actionSave,
            loading: s.saving,
            onPressed: () => _save(cubit),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.name,
    required this.picked,
    required this.current,
    required this.onPick,
  });

  final String name;
  final Uint8List? picked;
  final String? current;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final bytes = picked;
    final image = bytes != null ? MemoryImage(bytes) : networkPhoto(current);
    return Column(
      children: [
        PaoAvatar(name: name, image: image, size: 96),
        TextButton.icon(
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(context.t.accountChangePhoto),
          onPressed: onPick,
        ),
      ],
    );
  }
}
