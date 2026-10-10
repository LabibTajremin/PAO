import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/auth/presentation/phone_page.dart';
import 'package:pao_partner/features/profile/presentation/help_page.dart';
import 'package:pao_partner/features/profile/presentation/public_profile_page.dart';

import '../../support/harness.dart';
import '../jobs/fixtures.dart';
import 'fixtures.dart';

void main() {
  Future<Harness> start(
    WidgetTester tester, {
    String? bio,
    bool fail = false,
  }) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(
        '/v1/provider/profile',
        (s) => fail
            ? s.reply(500, apiError('INTERNAL'))
            : s.reply(200, profile(bio: bio)),
      )
      ..onGet('/v1/provider/rating', (s) => s.reply(200, rating()));
    await h.pumpApp(tester, Routes.profile);
    return h;
  }

  testWidgets('shows name, badge, level and rating; edits the bio', (
    tester,
  ) async {
    final h = await start(tester);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Level 1: Document verified'), findsOneWidget);
    expect(find.text('132 ratings'), findsOneWidget);
    expect(find.text('Tell customers about your work.'), findsOneWidget);
    await tester.tap(find.text('Edit bio'));
    await h.settle(tester);
    await tester.enterText(find.byType(TextField), 'x' * 501);
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.text('Keep it under 500 characters.'), findsOneWidget);
    h.http.onPut(
      '/v1/provider/profile',
      (s) => s.reply(200, profile(bio: 'Fixes fans fast.')),
    );
    await tester.enterText(find.byType(TextField), 'Fixes fans fast.');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.text('Fixes fans fast.'), findsOneWidget);
    expect(h.bodyOf('/v1/provider/profile'), {
      'bio': 'Fixes fans fast.',
      'language': 'en',
    });
    await tester.tap(find.text('Edit bio'));
    await h.settle(tester);
    h.http.onPut(
      '/v1/provider/profile',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.text('Our service had a problem. Please try again.'), findsOne);
  });

  testWidgets('a new photo is uploaded; a failure is shown', (tester) async {
    final h = await start(tester, bio: 'Hi');
    when(
      () => h.picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      ),
    ).thenAnswer((_) async => XFile.fromData(tinyPng));
    h.http.onPost(
      '/v1/provider/uploads',
      (s) => s.reply(422, apiError('UPLOAD_INVALID')),
    );
    await tester.tap(find.text('Change photo'));
    await h.settle(tester);
    expect(
      find.text('This file cannot be used. Try another photo.'),
      findsOneWidget,
    );
    expect((h.bodyOf('/v1/provider/uploads')! as Map)['purpose'], 'avatar');
  });

  testWidgets('the menu opens sub-pages and works when loading fails', (
    tester,
  ) async {
    final h = await start(tester, fail: true);
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Public profile'));
    await h.settle(tester);
    expect(find.byType(PublicProfilePage), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);
    await tester.tap(find.text('Help'));
    await h.settle(tester);
    expect(find.byType(HelpPage), findsOneWidget);
  });

  testWidgets('log out asks first, then signs out even if the call fails', (
    tester,
  ) async {
    final h = await start(tester);
    await tester.tap(find.text('Log out'));
    await h.settle(tester);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(h.services.sessions.signedIn, isTrue);
    h.http.onPost('/v1/auth/logout', (s) => s.reply(500, apiError('INTERNAL')));
    await tester.tap(find.text('Log out'));
    await h.settle(tester);
    await tester.tap(find.text('Log out').last);
    await h.settle(tester);
    expect(h.sent.any((o) => o.path == '/v1/auth/logout'), isTrue);
    expect(h.services.sessions.signedIn, isFalse);
    expect(h.services.gate.status, isNull);
    expect(find.byType(PhonePage), findsOneWidget);
  });
}
