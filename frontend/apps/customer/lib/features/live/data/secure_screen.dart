import 'package:flutter/services.dart';

/// Blocks screenshots and the recent-apps preview while a secret is on screen,
/// through Android's FLAG_SECURE set by `MainActivity` on the
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
      // iOS has no equivalent flag and tests have no platform; the code is
      // still shown.
    }
  }
}
