import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/job/presentation/job_text.dart';

import '../../support/harness.dart';

void main() {
  testWidgets('status labels and clock cover every state', (tester) async {
    late BuildContext context;
    await pumpPage(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    expect(
      [for (final s in BookingStatus.values) context.statusText(s)],
      [
        'Waiting for your answer',
        'Accepted',
        'On the way',
        'Arrived',
        'Job started',
        'Completed',
        'Closed',
        'Closed',
        'Cancelled',
      ],
    );
    expect(context.clock(const Duration(seconds: 65)), '1:05');
    expect(context.clock(const Duration(seconds: -3)), '0:00');
  });
}
