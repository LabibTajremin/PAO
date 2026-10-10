import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/shared/formats.dart';

import '../support/harness.dart';

void main() {
  testWidgets('calendar dates format without a zone shift', (tester) async {
    late String day;
    await pumpPage(
      tester,
      Builder(
        builder: (context) {
          day = context.day('2026-10-09');
          return const SizedBox.shrink();
        },
      ),
    );
    expect(day, '9 Oct 2026');
  });
}
