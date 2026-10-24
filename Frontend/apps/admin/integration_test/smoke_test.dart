import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pao_admin/features/auth/presentation/login_page.dart';
import 'package:pao_admin/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the real composition root starts and shows the login', (
    tester,
  ) async {
    await app.main();
    final login = find.byType(LoginPage);
    for (var i = 0; i < 100 && login.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(login, findsOneWidget);
  });
}
