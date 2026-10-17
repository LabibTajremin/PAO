import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/profile/domain/service_area_repository.dart';
import 'package:pao_partner/features/profile/presentation/services_cubit.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Working radii offered, in metres (ServiceAreaInput allows 1–30 km).
const radiusOptions = [3000, 5000, 8000, 12000, 20000, 30000];

/// Edits services, experience, home base and radius (M33).
class ServicesForm extends StatefulWidget {
  /// Creates the form for [area].
  const ServicesForm({required this.area, required this.location, super.key});

  /// The current setup.
  final ServiceArea area;

  /// The GPS, to set the home base.
  final LocationService location;

  @override
  State<ServicesForm> createState() => _ServicesFormState();
}

class _ServicesFormState extends State<ServicesForm> {
  late final _years = TextEditingController(
    text: '${widget.area.experienceYears}',
  );
  var _saving = false;

  @override
  void dispose() {
    _years.dispose();
    super.dispose();
  }

  void _say(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _useLocation() async {
    final point = await widget.location.current();
    if (!mounted) return;
    if (point == null) return _say(context.t.profLocationOff);
    context.read<ServicesCubit>().moveHome(
      Point(lat: point.lat, lng: point.lng),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final years = (int.tryParse(_years.text) ?? 0).clamp(0, 60);
    final failure = await context.read<ServicesCubit>().save(years);
    if (!mounted) return;
    setState(() => _saving = false);
    _say(context.failureText(failure) ?? context.t.profSaved);
  }

  Widget _homeBase(ServiceArea area) => PaoListRow(
    leading: const Icon(Icons.home_outlined),
    title: context.t.profHomeBase,
    subtitle: area.homeBase == null
        ? context.t.profHomeBaseMissing
        : context.t.profHomeBaseSet,
    trailing: TextButton(
      onPressed: _useLocation,
      child: Text(context.t.profUseLocation),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final area = widget.area;
    final cubit = context.read<ServicesCubit>();
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.lg),
      children: [
        _Choices<String>(
          title: t.profServicesPick(context.count(ServicesCubit.maxServices)),
          options: {for (final s in area.options) s.id: context.local(s.name)},
          isSelected: area.selected.contains,
          onTap: cubit.toggle,
        ),
        PaoTextField(
          label: t.profExperienceLabel,
          controller: _years,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: PaoSpace.xl),
        _Choices<int>(
          title: t.profRadius,
          options: {
            for (final m in radiusOptions)
              m: t.profRadiusKm(context.count(m ~/ 1000)),
          },
          isSelected: (m) => area.radiusM == m,
          onTap: cubit.setRadius,
        ),
        _homeBase(area),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: context.common.actionSave,
          loading: _saving,
          onPressed: area.selected.isEmpty || area.homeBase == null
              ? null
              : _save,
        ),
      ],
    );
  }
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.title,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final Map<T, String> options;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PaoSpace.xl),
    child: Column(
      spacing: PaoSpace.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: PaoSpace.sm,
          runSpacing: PaoSpace.sm,
          children: [
            for (final MapEntry(key: value, value: label) in options.entries)
              PaoChip(
                label: label,
                selected: isSelected(value),
                onTap: () => onTap(value),
              ),
          ],
        ),
      ],
    ),
  );
}
