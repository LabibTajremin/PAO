import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/widgets/step_body.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// M07: home base from the device position and a working radius.
class AreaStep extends StatefulWidget {
  /// Creates the step.
  const AreaStep({super.key});

  @override
  State<AreaStep> createState() => _AreaStepState();
}

class _AreaStepState extends State<AreaStep> {
  GeoPoint? _point;
  var _radiusKm = 8;
  var _locating = false;
  var _off = false;
  var _checked = false;

  Future<void> _locate() async {
    final location = context.read<LocationService>();
    setState(() => _locating = true);
    GeoPoint? point;
    await attempt(() async => point = await location.current());
    if (!mounted) return;
    setState(() {
      _locating = false;
      _point = point ?? _point;
      _off = point == null;
    });
  }

  Future<void> _save() async {
    setState(() => _checked = true);
    final p = _point;
    if (p == null) return;
    await context.read<EnrolmentCubit>().save(
      WorkArea(lat: p.lat, lng: p.lng, radiusM: _radiusKm * 1000),
    );
  }

  String _pin(BuildContext context) {
    final p = _point;
    if (p == null) return context.t.enrolAreaNoPin;
    return context.t.enrolAreaPinned(
      p.lat.toStringAsFixed(4),
      p.lng.toStringAsFixed(4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return StepBody(
      onNext: _save,
      children: [
        Text(t.enrolAreaHint),
        const SizedBox(height: PaoSpace.md),
        PaoMapFrame(label: _pin(context)),
        const SizedBox(height: PaoSpace.md),
        PaoButton(
          label: t.enrolAreaLocate,
          icon: Icons.my_location,
          variant: PaoButtonVariant.outline,
          loading: _locating,
          onPressed: _locate,
        ),
        if (_off || (_checked && _point == null))
          Text(
            _off ? t.enrolAreaOff : t.enrolAreaError,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.xl),
        Text(t.enrolAreaRadius(_radiusKm)),
        Slider(
          value: _radiusKm.toDouble(),
          min: 1,
          max: 30,
          divisions: 29,
          label: '$_radiusKm',
          onChanged: (v) => setState(() => _radiusKm = v.round()),
        ),
      ],
    );
  }
}
