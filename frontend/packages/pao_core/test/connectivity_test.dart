import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('follows the platform stream', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    final w = ConnectivityWatcher(changes: changes.stream);
    expect(w.value, isTrue);
    changes.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    expect(w.value, isFalse);
    changes.add([ConnectivityResult.none, ConnectivityResult.mobile]);
    await Future<void>.delayed(Duration.zero);
    expect(w.value, isTrue);
    w.dispose();
    await changes.close();
  });

  test('defaults to the plugin', () {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
          MockStreamHandler.inline(
            onListen: (_, sink) => sink.success(['wifi']),
          ),
        );
    ConnectivityWatcher().dispose();
  });
}
