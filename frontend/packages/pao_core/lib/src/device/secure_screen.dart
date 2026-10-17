import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Blocks screenshots and the recent-apps preview while a secret is on screen,
/// through Android's FLAG_SECURE set by each app's `MainActivity` on the
/// `pao/secure_screen` channel. A platform channel avoids a plugin for one
/// window flag.
class SecureScreen {
  /// Creates the bridge.
  const SecureScreen([this._channel = channel]);

  /// The channel `MainActivity` listens on.
  static const channel = MethodChannel('pao/secure_screen');

  final MethodChannel _channel;

  /// Turns protection [on] or off.
  Future<void> protect({required bool on}) async {
    try {
      await _channel.invokeMethod<void>('setSecure', on);
    } on MissingPluginException {
      // iOS has no equivalent flag and tests have no platform; the content is
      // still shown.
    }
  }
}

/// Keeps the screen protected while [child] is shown: a start code, or a
/// verification document (PRD §6.6, MASVS-PLATFORM-3).
class SecureArea extends StatefulWidget {
  /// Protects [child].
  const SecureArea({
    required this.child,
    this.secure = const SecureScreen(),
    super.key,
  });

  /// What must not be captured.
  final Widget child;

  /// The window flag bridge.
  final SecureScreen secure;

  @override
  State<SecureArea> createState() => _SecureAreaState();
}

class _SecureAreaState extends State<SecureArea> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.secure.protect(on: true));
  }

  @override
  void dispose() {
    unawaited(widget.secure.protect(on: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
