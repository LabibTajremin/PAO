import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/location/data/api_address_repository.dart';
import 'package:pao_customer/features/location/presentation/address_form.dart';
import 'package:pao_customer/features/location/presentation/permission_view.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Set location after sign-up (C06, C34) and add or edit an address (C25).
class AddressPage extends StatefulWidget {
  /// Creates the page; [addressId] edits that address and [onboarding] is the
  /// sign-up step, which explains the permission first and then goes home.
  const AddressPage({
    required this.services,
    this.addressId,
    this.onboarding = false,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// The address to edit, if any.
  final String? addressId;

  /// Whether this is the sign-up step.
  final bool onboarding;

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  /// Null until the customer answers the explainer.
  bool? _locate;

  void _saved(Address _) {
    if (widget.onboarding) return context.go(Routes.home);
    if (context.canPop()) return context.pop(true);
    context.go(Routes.accountPage('addresses'));
  }

  Future<Address> _find(String id) async {
    final all = await ApiAddressRepository(widget.services.api).list();
    for (final a in all) {
      if (a.id == id) return a;
    }
    throw const ApiFailure('NOT_FOUND', status: 404);
  }

  String _title(BuildContext context) {
    if (widget.onboarding) return context.t.locTitleSet;
    return widget.addressId == null
        ? context.t.locTitleNew
        : context.t.locTitleEdit;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PaoAppBar(title: _title(context)),
    body: _body(),
  );

  Widget _body() {
    final id = widget.addressId;
    if (id != null) return _edit(id);
    if (widget.onboarding && _locate == null) {
      return PermissionView(
        onAllow: () => setState(() => _locate = true),
        onManual: () => setState(() => _locate = false),
      );
    }
    return AddressForm(
      services: widget.services,
      onSaved: _saved,
      locateNow: _locate ?? false,
    );
  }

  Widget _edit(String id) => BlocProvider(
    create: (_) => LoadCubit<Address>(() => _find(id)).loading(),
    child: BlocBuilder<LoadCubit<Address>, ViewState<Address>>(
      builder: (context, state) => ViewStateView<Address>(
        state: state,
        onRetry: context.read<LoadCubit<Address>>().load,
        builder: (_, address) => AddressForm(
          services: widget.services,
          onSaved: _saved,
          editing: address,
        ),
      ),
    ),
  );
}
