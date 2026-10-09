import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/app.dart';

void main() {
  testWidgets('boots into the placeholder screen', (tester) async {
    await tester.pumpWidget(const PaoApp());
    expect(find.text('PAO Partner'), findsWidgets);
  });
}
