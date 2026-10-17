import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/jobs/presentation/job_detail_page.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

void main() {
  Future<Harness> start(WidgetTester tester) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester, Routes.job(bookingId, 'report'));
    return h;
  }

  void camera(Harness h, {bool cancel = false}) =>
      when(() => h.picker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => cancel ? null : XFile.fromData(tinyPng));

  Future<void> describe(WidgetTester tester, String text) =>
      tester.enterText(find.byType(TextField), text);

  testWidgets('validates, then files a report and shows the ticket', (
    tester,
  ) async {
    final h = await start(tester);
    await tester.tap(find.text('Send report'));
    await h.settle(tester);
    expect(find.text('Choose a reason.'), findsOneWidget);
    expect(find.text('Write between 10 and 1000 characters.'), findsOneWidget);
    await tester.tap(find.text('Payment problem'));
    await describe(tester, 'The customer refused to pay.');
    h.http.onPost(
      '/v1/provider/jobs/$bookingId/reports',
      (s) => s.reply(422, apiError('VALIDATION_FAILED')),
    );
    await tester.tap(find.text('Send report'));
    await h.settle(tester);
    expect(find.text('Please check the highlighted fields.'), findsOneWidget);
    h.http.onPost(
      '/v1/provider/jobs/$bookingId/reports',
      (s) => s.reply(201, complaint()),
    );
    await tester.tap(find.text('Send report'));
    await h.settle(tester);
    expect(h.bodyOf('/v1/provider/jobs/$bookingId/reports'), {
      'reason': 'payment',
      'description': 'The customer refused to pay.',
    });
    expect(
      find.text('Your ticket number is TCK-002341. Our team will contact you.'),
      findsOneWidget,
    );
    h.http.onGet(
      '/v1/provider/jobs/$bookingId',
      (s) => s.reply(200, booking()),
    );
    await tester.tap(find.text('Back to job'));
    await h.settle(tester);
    expect(find.byType(JobDetailPage), findsOneWidget);
  });

  testWidgets('adds and removes photos; a failed upload is shown', (
    tester,
  ) async {
    final h = await start(tester);
    camera(h, cancel: true);
    await tester.tap(find.text('Add photo'));
    await h.settle(tester);
    expect(find.text('Photos (0 of 5)'), findsOneWidget);
    camera(h);
    await tester.tap(find.text('Add photo'));
    await h.settle(tester);
    await tester.tap(find.text('Add photo'));
    await h.settle(tester);
    expect(find.text('Photos (2 of 5)'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove photo').first);
    await h.settle(tester);
    expect(find.text('Photos (1 of 5)'), findsOneWidget);
    h.http.onPost(
      '/v1/provider/uploads',
      (s) => s.reply(422, apiError('UPLOAD_INVALID')),
    );
    await tester.tap(find.text('Customer behaviour'));
    await describe(tester, 'Shouted at me during the job.');
    await tester.ensureVisible(find.text('Send report'));
    await tester.tap(find.text('Send report'));
    await h.settle(tester);
    expect(
      find.text('This file cannot be used. Try another photo.'),
      findsOneWidget,
    );
    expect(h.bodyOf('/v1/provider/uploads'), {
      'purpose': 'complaint_photo',
      'contentType': 'image/jpeg',
      'sizeBytes': isA<int>(),
    });
    expect(find.byType(Image), findsOneWidget);
  });
}
