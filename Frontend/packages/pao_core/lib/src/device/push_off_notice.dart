import 'package:flutter/material.dart';
import 'package:pao_core/src/device/push.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A strip saying notifications are blocked, with a shortcut to the phone's
/// settings. It checks again whenever the app returns to the foreground,
/// which is how the user comes back from those settings.
class PushOffNotice extends StatefulWidget {
  /// Creates the notice for [push].
  const PushOffNotice({required this.push, super.key});

  /// Where the permission state comes from.
  final PushService push;

  @override
  State<PushOffNotice> createState() => _PushOffNoticeState();
}

class _PushOffNoticeState extends State<PushOffNotice>
    with WidgetsBindingObserver {
  bool _off = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check().ignore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check().ignore();
  }

  Future<void> _check() async {
    final off = !await widget.push.allowed();
    if (mounted && off != _off) setState(() => _off = off);
  }

  @override
  Widget build(BuildContext context) {
    if (!_off) return const SizedBox.shrink();
    final t = PaoL10n.of(context);
    return Material(
      color: context.pao.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PaoSpace.lg,
          PaoSpace.sm,
          PaoSpace.sm,
          PaoSpace.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined, color: context.pao.action),
            const SizedBox(width: PaoSpace.sm),
            Expanded(child: Text(t.pushOffBody)),
            TextButton(
              onPressed: widget.push.openSettings,
              child: Text(t.pushOffAction),
            ),
          ],
        ),
      ),
    );
  }
}
