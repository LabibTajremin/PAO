import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_admin/features/level2/presentation/level2_labels.dart';
import 'package:pao_admin/features/level2/presentation/provider_search.dart';
import 'package:pao_admin/features/level2/presentation/schedule_cubit.dart';
import 'package:pao_admin/features/level2/presentation/when_fields.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Asks for a Level 1 provider, one of their services, a Dhaka date and time
/// and a place, then books the session; resolves with it, or null.
Future<Level2Session?> showScheduleDialog(
  BuildContext context, {
  required Level2Repository repo,
  required DateTime Function() now,
}) => showDialog<Level2Session>(
  context: context,
  builder: (_) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => ScheduleCubit(repo)),
      BlocProvider(create: (_) => ProviderSearchCubit(repo, level: 1)),
    ],
    child: ScheduleForm(now: now),
  ),
);

/// The schedule form inside its dialog.
class ScheduleForm extends StatefulWidget {
  /// Creates the form; [now] gives the earliest date.
  const ScheduleForm({required this.now, super.key});

  /// Current time.
  final DateTime Function() now;

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _place = TextEditingController();
  late final DateTime _today = dhakaDay(widget.now());
  late DateTime _day = _today.add(const Duration(days: 1));
  var _time = const TimeOfDay(hour: 10, minute: 0);
  AdminProviderSummary? _provider;
  String? _service;
  String? _problem;

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  void _pick(AdminProviderSummary p) => setState(() {
    _provider = p;
    _service = p.services?.firstOrNull?.id;
  });

  Future<void> _submit() async {
    final at = dhakaInstant(_day, _time);
    final t = context.t;
    final problem =
        _provider == null || _service == null || _place.text.trim().isEmpty
        ? t.level2ScheduleMissing
        : at.isAfter(widget.now())
        ? null
        : t.level2PastTime;
    setState(() => _problem = problem);
    if (problem != null) return;
    await context.read<ScheduleCubit>().submit(
      Level2Booking(
        providerId: _provider!.id,
        serviceId: _service!,
        at: at,
        location: _place.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ScheduleCubit, ScheduleState>(
        listenWhen: (_, s) => s.booked != null,
        listener: (context, s) => Navigator.pop(context, s.booked),
        builder: (context, s) => AlertDialog(
          title: Text(context.t.level2ScheduleTitle),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(child: _fields(context, s)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.common.actionCancel),
            ),
            PaoButton(
              label: context.t.level2ScheduleSubmit,
              expand: false,
              loading: s.busy,
              onPressed: _submit,
            ),
          ],
        ),
      );

  Widget _fields(BuildContext context, ScheduleState s) {
    final t = context.t;
    final error = _problem ?? context.level2Failure(s.failure);
    final p = _provider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaoSpace.md,
      children: [
        if (p == null)
          ProviderSearch(onPick: _pick)
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: PaoAvatar(name: p.name, size: 36),
            title: Text(p.name),
            subtitle: p.phone == null ? null : Text(p.phone!),
            trailing: TextButton(
              onPressed: () => setState(() => _provider = null),
              child: Text(t.level2ChangeProvider),
            ),
          ),
        if (p != null) _serviceField(context, p),
        WhenFields(
          day: _day,
          time: _time,
          first: _today,
          onDay: (d) => setState(() => _day = d),
          onTime: (v) => setState(() => _time = v),
        ),
        PaoTextField(
          label: t.level2Location,
          hint: t.level2LocationHint,
          controller: _place,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
        ),
        if (error != null)
          Text(error, style: const TextStyle(color: PaoColors.danger)),
      ],
    );
  }

  Widget _serviceField(BuildContext context, AdminProviderSummary p) {
    final services = p.services ?? const [];
    if (services.isEmpty) return Text(context.t.level2NoServices);
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      label: Text(context.t.level2Service),
      initialSelection: _service,
      onSelected: (id) => setState(() => _service = id),
      dropdownMenuEntries: [
        for (final s in services)
          DropdownMenuEntry(value: s.id, label: context.local(s.name)),
      ],
    );
  }
}

/// The Asia/Dhaka calendar day of [instant].
DateTime dhakaDay(DateTime instant) {
  final wall = instant.toUtc().add(dhakaOffset);
  return DateTime(wall.year, wall.month, wall.day);
}

/// The instant at Dhaka wall [time] on [day], in UTC as the API expects.
DateTime dhakaInstant(DateTime day, TimeOfDay time) => DateTime.utc(
  day.year,
  day.month,
  day.day,
  time.hour,
  time.minute,
).subtract(dhakaOffset);
