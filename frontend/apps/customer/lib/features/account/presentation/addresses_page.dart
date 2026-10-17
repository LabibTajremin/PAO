import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/account/data/api_account_repository.dart';
import 'package:pao_customer/features/account/domain/account_repository.dart';
import 'package:pao_customer/features/account/presentation/address_card.dart';
import 'package:pao_customer/features/account/presentation/addresses_cubit.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Saved addresses (C24): default, edit, delete and add.
class AddressesPage extends StatelessWidget {
  /// Creates the page.
  const AddressesPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        AddressesCubit(ApiAddressesRepository(services.api)).loading(),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.accountAddresses),
      body: BlocBuilder<AddressesCubit, ViewState<List<Address>>>(
        builder: (context, state) {
          final cubit = context.read<AddressesCubit>();
          return ViewStateView<List<Address>>(
            state: state,
            onRetry: cubit.load,
            isEmpty: (list) => list.isEmpty,
            empty: PaoEmptyState(
              icon: Icons.place_outlined,
              title: context.t.accountAddressesEmpty,
              message: context.t.accountAddressesEmptyBody,
              action: _AddButton(full: false, onAdded: cubit.refresh),
            ),
            builder: (_, list) => _List(addresses: list),
          );
        },
      ),
    ),
  );
}

class _List extends StatelessWidget {
  const _List({required this.addresses});

  final List<Address> addresses;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddressesCubit>();
    final full = addresses.length >= maxAddresses;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        for (final a in addresses) AddressCard(address: a),
        const SizedBox(height: PaoSpace.md),
        if (full)
          Padding(
            padding: const EdgeInsets.only(bottom: PaoSpace.sm),
            child: Text(
              context.t.accountAddressLimit(context.count(maxAddresses)),
              textAlign: TextAlign.center,
            ),
          ),
        _AddButton(full: full, onAdded: cubit.refresh),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.full, required this.onAdded});

  final bool full;
  final Future<void> Function() onAdded;

  @override
  Widget build(BuildContext context) => PaoButton(
    label: context.t.accountAddressAdd,
    icon: Icons.add,
    expand: false,
    onPressed: full
        ? null
        : () async {
            await context.push<void>(Routes.addressNew);
            await onAdded();
          },
  );
}
