import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/photos.dart';

import '../support/harness.dart';

void main() {
  test('a photo URL becomes a network image', () {
    expect(networkPhoto(null), isNull);
    expect(networkPhoto('https://cdn.test/a.jpg'), isA<NetworkImage>());
  });

  testWidgets('API dates read in the app language', (tester) async {
    late String text;
    await pumpPage(
      tester,
      Builder(
        builder: (context) {
          text = context.day('2026-10-09');
          return const SizedBox.shrink();
        },
      ),
    );
    expect(text, '9 Oct 2026');
  });
}
