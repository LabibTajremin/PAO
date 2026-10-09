import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Whether the device has any network; drives the offline banner (C36).
class ConnectivityWatcher extends ValueNotifier<bool> {
  /// Watches [changes]; the platform stream is used when none is given.
  ConnectivityWatcher({Stream<List<ConnectivityResult>>? changes})
    : super(true) {
    _sub = (changes ?? Connectivity().onConnectivityChanged).listen(
      (results) => value = results.any((r) => r != ConnectivityResult.none),
    );
  }

  late final StreamSubscription<List<ConnectivityResult>> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
