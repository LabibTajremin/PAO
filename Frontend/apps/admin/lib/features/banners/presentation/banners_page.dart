import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/banners/data/api_banner_repository.dart';
import 'package:pao_admin/features/banners/presentation/banner_dialog.dart';
import 'package:pao_admin/features/banners/presentation/banners_cubit.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_labels.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/console_page.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// The customer home's banners: add, edit, order, publish and delete.
class BannersPage extends StatelessWidget {
  /// Creates the page.
  const BannersPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => BannersCubit(ApiBannerRepository(services.api)).loading(),
    child: BlocBuilder<BannersCubit, ViewState<BannersData>>(
      builder: (context, state) {
        final cubit = context.read<BannersCubit>();
        final data = switch (state) {
          ViewData(:final data) => data,
          _ => null,
        };
        return ConsolePage(
          title: context.t.bannersTitle,
          subtitle: context.t.bannersSubtitle,
          actions: [
            if (data != null)
              PaoButton(
                label: context.t.bannersNew,
                icon: Icons.add,
                expand: false,
                onPressed: () => _edit(context, cubit, data, null),
              ),
          ],
          child: ViewStateView<BannersData>(
            state: state,
            onRetry: cubit.load,
            isEmpty: (d) => d.banners.isEmpty,
            empty: PaoEmptyState(
              title: context.t.bannersEmptyTitle,
              message: context.t.bannersEmptyBody,
            ),
            builder: (context, d) => ListView.separated(
              padding: const EdgeInsets.all(PaoSpace.xxl),
              itemCount: d.banners.length,
              separatorBuilder: (_, _) => const SizedBox(height: PaoSpace.md),
              itemBuilder: (context, i) => _BannerRow(
                banner: d.banners[i],
                onTap: () => _edit(context, cubit, d, d.banners[i]),
              ),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _edit(
    BuildContext context,
    BannersCubit cubit,
    BannersData data,
    Banner? banner,
  ) async {
    final done = await showBannerDialog(
      context,
      cubit: cubit,
      services: data.services,
      banner: banner,
    );
    if (done != null && context.mounted) showDone(context, done);
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({required this.banner, required this.onTap});

  final Banner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = banner.subtitle;
    return PaoCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.local(banner.title),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitle != null) Text(context.local(subtitle)),
              ],
            ),
          ),
          Text('#${banner.sortOrder}'),
          const SizedBox(width: PaoSpace.md),
          PublishedBadge(published: banner.published),
        ],
      ),
    );
  }
}
