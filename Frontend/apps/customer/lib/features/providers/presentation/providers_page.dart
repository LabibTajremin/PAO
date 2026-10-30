import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/providers/data/api_providers_repository.dart';
import 'package:pao_customer/features/providers/presentation/provider_card.dart';
import 'package:pao_customer/features/providers/presentation/providers_cubit.dart';
import 'package:pao_customer/features/providers/presentation/sort_filter_sheet.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Providers near the customer for a service (C10, C39, C40).
class ProvidersPage extends StatelessWidget {
  /// Creates the page; [query] carries the booking draft.
  const ProvidersPage({
    required this.services,
    required this.serviceId,
    required this.query,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The service.
  final String serviceId;

  /// The route's query parameters.
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final draft = BookingDraft.fromQuery({...query, 'service': serviceId});
    final repo = ApiProvidersRepository(services.api);
    return Scaffold(
      appBar: PaoAppBar(title: context.t.provTitle),
      body: draft == null || draft.items.isEmpty
          ? PaoEmptyState(
              icon: Icons.checklist,
              title: context.t.provNoDraft,
              action: PaoButton(
                label: context.t.provChooseItems,
                expand: false,
                onPressed: () =>
                    context.pushReplacement(Routes.serviceOf(serviceId)),
              ),
            )
          : BlocProvider(
              create: (_) => LoadCubit<Address?>(repo.searchAddress).loading(),
              child: BlocBuilder<LoadCubit<Address?>, ViewState<Address?>>(
                builder: (context, state) => ViewStateView<Address?>(
                  state: state,
                  onRetry: context.read<LoadCubit<Address?>>().load,
                  isEmpty: (a) => a == null,
                  empty: const _NoAddress(),
                  builder: (_, address) =>
                      BlocProvider<PagedCubit<ProviderCard>>(
                        create: (_) => ProvidersCubit(
                          repo,
                          draft: draft,
                          addressId: address!.id,
                        ).loading(),
                        child: _List(draft: draft),
                      ),
                ),
              ),
            ),
    );
  }
}

class _NoAddress extends StatelessWidget {
  const _NoAddress();

  @override
  Widget build(BuildContext context) => PaoEmptyState(
    icon: Icons.add_location_alt_outlined,
    title: context.t.provNoAddressTitle,
    message: context.t.provNoAddressBody,
    action: PaoButton(
      label: context.t.homeAddAddress,
      expand: false,
      onPressed: () async {
        final cubit = context.read<LoadCubit<Address?>>();
        await context.push<bool>(Routes.addressNew);
        await cubit.load();
      },
    ),
  );
}

class _List extends StatelessWidget {
  const _List({required this.draft});

  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PagedCubit<ProviderCard>>() as ProvidersCubit;
    return PagedView<ProviderCard>(
      header: [
        BlocBuilder<PagedCubit<ProviderCard>, PagedState<ProviderCard>>(
          builder: (context, _) => _Header(
            summary: draft.items.length == 1 ? cubit.summary : null,
            onSortFilter: () async {
              final q = await showSortFilterSheet(context, cubit.query);
              if (q != null) await cubit.apply(q);
            },
          ),
        ),
      ],
      itemBuilder: (context, card) => ProviderCardView(
        card: card,
        onTap: () => context.push(
          Uri(
            path: Routes.providerOf(card.id),
            queryParameters: draft.toQuery(),
          ).toString(),
        ),
      ),
      empty: PaoEmptyState(
        icon: Icons.person_search_outlined,
        title: context.t.provEmptyTitle,
        message: context.t.provEmptyBody,
        action: PaoButton(
          label: context.common.actionRetry,
          variant: PaoButtonVariant.soft,
          expand: false,
          onPressed: cubit.load,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary, required this.onSortFilter});

  final PriceSummary? summary;
  final VoidCallback onSortFilter;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: Row(
        children: [
          Expanded(
            child: s == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t.provPriceFor,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      PaoMoneyText(
                        s.total,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.tune),
            label: Text(context.t.provSortFilter),
            onPressed: onSortFilter,
          ),
        ],
      ),
    );
  }
}
