import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/catalog/domain/catalog_repository.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_cubits.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_labels.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// A sub-service's price: a new price applies to bookings made from now on,
/// and every earlier version stays in the history (PRD §4).
class PricePanel extends StatefulWidget {
  /// Creates the panel.
  const PricePanel({
    required this.repository,
    required this.sub,
    required this.onChanged,
    super.key,
  });

  /// Reads and changes prices.
  final CatalogRepository repository;

  /// The sub-service.
  final SubService sub;

  /// Told after a price change so the service view shows it.
  final Future<void> Function() onChanged;

  @override
  State<PricePanel> createState() => _PricePanelState();
}

class _PricePanelState extends State<PricePanel> {
  final _amount = TextEditingController();
  String? _error;
  var _busy = false;
  var _changed = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _change(PriceCubit cubit) async {
    final problem = checkMoney(context.t, _amount.text);
    setState(() {
      _error = problem;
      _changed = false;
    });
    if (problem != null) return;
    setState(() => _busy = true);
    final failure = await cubit.change(parsePaisa(_amount.text)!);
    if (failure == null) await widget.onChanged();
    if (!mounted) return;
    if (failure == null) _amount.clear();
    setState(() {
      _busy = false;
      _changed = failure == null;
      _error = context.failureText(failure);
    });
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PriceCubit(widget.repository, widget.sub.id).loading(),
    child: BlocBuilder<PriceCubit, ViewState<List<PriceVersion>>>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaoSpace.md,
        children: [
          ..._form(context),
          const Divider(),
          Text(
            context.t.catalogPriceHistory,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ViewStateView<List<PriceVersion>>(
            state: state,
            onRetry: context.read<PriceCubit>().load,
            isEmpty: (versions) => versions.isEmpty,
            empty: Text(context.t.catalogNoPrices),
            builder: (_, versions) => _History(versions: versions),
          ),
        ],
      ),
    ),
  );

  List<Widget> _form(BuildContext context) {
    final t = context.t;
    return [
      Text(t.catalogPriceNote),
      PaoTextField(
        label: t.catalogNewPrice(unitLabel(t, widget.sub.unit)),
        prefix: '৳',
        controller: _amount,
        keyboardType: TextInputType.number,
        error: _error,
      ),
      if (_changed)
        Text(
          t.catalogPriceChanged,
          style: const TextStyle(color: PaoColors.success),
        ),
      PaoButton(
        label: t.catalogSetPrice,
        loading: _busy,
        onPressed: () => _change(context.read<PriceCubit>()),
      ),
    ];
  }
}

class _History extends StatelessWidget {
  const _History({required this.versions});

  /// Newest first.
  final List<PriceVersion> versions;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (i, v) in versions.indexed)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.money(v.amount)),
          subtitle: Text(
            context.t.catalogPriceSince(
              context.when(v.effectiveFrom),
              v.createdBy.substring(0, 8),
            ),
          ),
          trailing: i == 0
              ? PaoBadge(
                  label: context.t.catalogCurrentPrice,
                  tone: PaoTone.success,
                )
              : null,
        ),
    ],
  );
}
