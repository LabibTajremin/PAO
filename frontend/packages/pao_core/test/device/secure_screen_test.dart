import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(
    () => messenger.setMockMethodCallHandler(SecureScreen.channel, null),
  );

  testWidgets('a secure area flags the window while it is shown', (
    tester,
  ) async {
    final calls = <Object?>[];
    messenger.setMockMethodCallHandler(SecureScreen.channel, (call) async {
      calls.add('${call.method}:${call.arguments}');
      return null;
    });
    await tester.pumpWidget(const SecureArea(child: SizedBox()));
    expect(calls, ['setSecure:true']);
    await tester.pumpWidget(const SizedBox());
    expect(calls, ['setSecure:true', 'setSecure:false']);
  });

  test('platforms without the channel just show the content', () async {
    await const SecureScreen().protect(on: true);
  });
}
