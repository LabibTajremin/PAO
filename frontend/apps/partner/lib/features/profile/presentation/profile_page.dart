import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/profile/data/api_profile_repository.dart';
import 'package:pao_partner/features/profile/domain/profile_repository.dart';
import 'package:pao_partner/features/profile/presentation/profile_cubit.dart';
import 'package:pao_partner/features/profile/presentation/profile_header.dart';
import 'package:pao_partner/features/profile/presentation/profile_menu.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_partner/shared/load_on_create.dart';
import 'package:pao_ui/pao_ui.dart';

/// The profile tab: photo, name, badge, rating, bio and every sub-page (M28).
class ProfilePage extends StatelessWidget {
  /// Creates the page.
  const ProfilePage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ProfileCubit(ApiProfileRepository(services.api)).loading(),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.profTitle),
      body: ListView(
        padding: const EdgeInsets.all(PaoSpace.lg),
        children: [
          BlocBuilder<ProfileCubit, ViewState<ProfileOverview>>(
            builder: (context, state) => ViewStateView<ProfileOverview>(
              state: state,
              onRetry: context.read<ProfileCubit>().load,
              builder: (_, overview) =>
                  ProfileHeader(overview: overview, photos: services.photos),
            ),
          ),
          const SizedBox(height: PaoSpace.lg),
          // The menu stays usable when the profile fails to load, so the
          // provider can still change language, get help or log out.
          ProfileMenu(services: services),
        ],
      ),
    ),
  );
}
