import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/features/home/data/service_heartbeat.dart';
import 'package:pao_partner/features/home/domain/heartbeat.dart';

class _Beat implements Heartbeat {
  final calls = <String>[];

  @override
  void start(Duration every, Future<void> Function() beat) =>
      calls.add('start ${every.inSeconds}');

  @override
  void stop() => calls.add('stop');
}

const OnlineNotice _notice = (
  title: 'You are online',
  body: 'Sharing your location',
);
const _every = Duration(seconds: 30);

Future<void> _noBeat() async {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> sent;

  void answer(Object? Function(MethodCall call) reply) =>
      messenger.setMockMethodCallHandler(presenceChannel, (call) async {
        sent.add(call);
        return reply(call);
      });

  setUp(() => sent = []);
  tearDown(() => messenger.setMockMethodCallHandler(presenceChannel, null));

  test('starts the service with the notice and the inner beat', () async {
    answer((_) => null);
    final inner = _Beat();
    ServiceHeartbeat(inner, _notice, android: true).start(_every, _noBeat);
    await pumpEventQueue();
    expect(inner.calls, ['start 30']);
    expect(sent.single.method, 'start');
    expect(sent.single.arguments, {
      'title': 'You are online',
      'body': 'Sharing your location',
    });
  });

  test('stops the inner beat and the service', () async {
    answer((_) => null);
    final inner = _Beat();
    ServiceHeartbeat(inner, _notice, android: true).stop();
    await pumpEventQueue();
    expect(inner.calls, ['stop']);
    expect(sent.single.method, 'stop');
    expect(sent.single.arguments, isNull);
  });

  test('keeps beating when Android refuses the service', () async {
    answer((_) => throw PlatformException(code: 'unavailable'));
    final inner = _Beat();
    ServiceHeartbeat(inner, _notice, android: true).start(_every, _noBeat);
    await pumpEventQueue();
    expect(sent.single.method, 'start');
    expect(inner.calls, ['start 30']);
  });

  test('keeps beating when the platform has no service', () async {
    final inner = _Beat();
    ServiceHeartbeat(inner, _notice, android: true)
      ..start(_every, _noBeat)
      ..stop();
    await pumpEventQueue();
    expect(inner.calls, ['start 30', 'stop']);
  });

  test('never calls the channel off Android', () async {
    answer((_) => null);
    final inner = _Beat();
    ServiceHeartbeat(inner, _notice, android: false)
      ..start(_every, _noBeat)
      ..stop();
    await pumpEventQueue();
    expect(sent, isEmpty);
    expect(inner.calls, ['start 30', 'stop']);
  });

  test('defaults to the platform the app runs on', () async {
    answer((_) => null);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    ServiceHeartbeat(_Beat(), _notice).stop();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    ServiceHeartbeat(_Beat(), _notice).stop();
    debugDefaultTargetPlatformOverride = null;
    await pumpEventQueue();
    expect(sent.map((c) => c.method), ['stop']);
  });
}
