import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/location/data/api_address_repository.dart';
import 'package:pao_customer/features/location/presentation/address_form_cubit.dart';
import 'package:pao_customer/features/location/presentation/address_parts.dart';
import 'package:pao_customer/features/location/presentation/map_picker.dart';
import 'package:pao_customer/features/location/presentation/place_search_cubit.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Pin, search, label and lines of an address (C06, C25).
class AddressForm extends StatefulWidget {
  /// Creates the form; [editing] pre-fills it and [locateNow] reads the device
  /// position straight away.
  const AddressForm({
    required this.services,
    required this.onSaved,
    this.editing,
    this.locateNow = false,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Called with the stored address.
  final ValueChanged<Address> onSaved;

  /// The address being edited, if any.
  final Address? editing;

  /// Whether to read the device position on open.
  final bool locateNow;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late final _line1 = TextEditingController(text: widget.editing?.line1);
  late final _line2 = TextEditingController(text: widget.editing?.line2);
  late final _area = TextEditingController(text: widget.editing?.area);
  final _search = TextEditingController();

  @override
  void dispose() {
    for (final c in [_line1, _line2, _area, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  AddressFormCubit _create(String language) {
    final s = widget.services;
    final cubit = AddressFormCubit(
      repo: ApiAddressRepository(s.api),
      location: s.location,
      places: s.places,
      language: language,
      editing: widget.editing,
    );
    if (widget.locateNow) {
      unawaited(cubit.locate());
    } else if (widget.editing != null) {
      unawaited(cubit.moveTo(cubit.state.point));
    }
    return cubit;
  }

  void _changed(BuildContext context, AddressFormState s) {
    final saved = s.saved;
    if (saved != null) return widget.onSaved(saved);
    final place = s.place!;
    _line1.text = place.title;
    if (place.area case final area?) _area.text = area;
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.services.locale.value.languageCode;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => _create(language)),
        BlocProvider(
          create: (_) =>
              PlaceSearchCubit(widget.services.places, language: language),
        ),
      ],
      child: BlocConsumer<AddressFormCubit, AddressFormState>(
        listenWhen: (a, b) => b.saved != null || a.place != b.place,
        listener: _changed,
        builder: _fields,
      ),
    );
  }

  List<Widget> _lines(BuildContext context, AddressFormState s) => [
    PaoTextField(
      label: context.t.locLine1,
      hint: context.t.locLine1Hint,
      controller: _line1,
      error: s.invalidLine1 ? context.t.locLine1Invalid : null,
    ),
    const SizedBox(height: PaoSpace.md),
    PaoTextField(label: context.t.locLine2, controller: _line2),
    const SizedBox(height: PaoSpace.md),
    PaoTextField(label: context.t.locArea, controller: _area),
  ];

  Widget _fields(BuildContext context, AddressFormState s) {
    final cubit = context.read<AddressFormCubit>();
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        MapPicker(
          point: s.point,
          label: s.place?.area ?? s.place?.title ?? t.locPinHere,
          onMoved: cubit.moveTo,
        ),
        _Locate(state: s, onTap: cubit.locate),
        CoverageNote(coverage: s.coverage),
        const SizedBox(height: PaoSpace.md),
        PlaceSearchBox(controller: _search, onPick: cubit.pick),
        const SizedBox(height: PaoSpace.lg),
        LabelChips(selected: s.label, onChoose: cubit.choose),
        const SizedBox(height: PaoSpace.lg),
        ..._lines(context, s),
        if (context.failureText(s.failure) case final error?)
          Padding(
            padding: const EdgeInsets.only(top: PaoSpace.md),
            child: Text(error, style: const TextStyle(color: PaoColors.danger)),
          ),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: t.locSave,
          loading: s.saving,
          onPressed: () => cubit.save(
            line1: _line1.text,
            line2: _line2.text,
            area: _area.text,
          ),
        ),
      ],
    );
  }
}

class _Locate extends StatelessWidget {
  const _Locate({required this.state, required this.onTap});

  final AddressFormState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        icon: state.locating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(context.t.locUseCurrent),
        onPressed: state.locating ? null : onTap,
      ),
      if (state.locateFailed)
        Text(
          context.t.locLocateFailed,
          style: const TextStyle(color: PaoColors.warning),
        ),
    ],
  );
}
