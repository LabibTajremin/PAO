import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';

import '../../support/harness.dart';
import '../jobs/fixtures.dart';
import 'fixtures.dart';

void main() {
  Future<Harness> start(WidgetTester tester) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    return h;
  }

  testWidgets('level explains each level and the Level 2 status', (
    tester,
  ) async {
    final h = await start(tester);
    final cases = <Map<String, Object?>, String>{
      verificationStatus(level2: {'eligible': true}):
          'You can book a skill check. Call PAO support to arrange one.',
      verificationStatus(
        level2: {
          'eligible': true,
          'nextSession': {
            'id': '15151515-1515-1515-1515-151515151515',
            'providerId': '11111111-1111-1111-1111-111111111111',
            'serviceId': serviceId,
            'scheduledAt': '2026-10-12T04:00:00Z',
            'location': 'PAO Banani',
            'status': 'scheduled',
          },
        },
      ): 'Your skill check is on 12 Oct 2026, 10:00 AM at PAO Banani.',
      verificationStatus(
        level2: {'eligible': false, 'retryAfter': '2026-11-01T00:00:00Z'},
      ): 'You can try the skill check again after 1 Nov 2026.',
      verificationStatus(level: 0):
          'Reach Level 1 first; then PAO can check your work in person.',
      verificationStatus(level: 2): 'You are a PAO Verified Pro.',
    };
    await h.pumpApp(tester, Routes.profile);
    for (final MapEntry(key: reply, value: text) in cases.entries) {
      h.http.onGet('/v1/provider/verification', (s) => s.reply(200, reply));
      await h.go(tester, Routes.profilePage('level'));
      expect(find.text(text), findsOneWidget);
      await h.go(tester, Routes.profile);
    }
    expect(find.text('Level 0: Registered'), findsNothing);
    h.http.onGet(
      '/v1/provider/verification',
      (s) => s.reply(200, verificationStatus()),
    );
    await h.go(tester, Routes.profilePage('level'));
    expect(find.text('Level 1: Document verified'), findsNWidgets(2));
    expect(find.text('Level 2: Skill verified'), findsOneWidget);
  });

  testWidgets('services and area are edited and saved', (tester) async {
    final h = await start(tester);
    h.http
      ..onGet('/v1/provider/profile', (s) => s.reply(200, profile()))
      ..onGet('/v1/provider/catalog', (s) => s.reply(200, catalog()))
      ..onPut(
        '/v1/provider/enrolment/services',
        (s) => s.reply(200, enrolment()),
      )
      ..onPut('/v1/provider/enrolment/area', (s) => s.reply(200, enrolment()));
    await h.pumpApp(tester, Routes.profilePage('services'));
    expect(find.text('Hidden'), findsNothing);
    await tester.tap(find.text('Plumber'));
    await tester.tap(find.text('12 km'));
    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.text('Saved'), findsOneWidget);
    expect(h.bodyOf('/v1/provider/enrolment/services'), {
      'serviceIds': [serviceId, otherServiceId],
      'experienceYears': 10,
    });
    expect(h.bodyOf('/v1/provider/enrolment/area'), {
      'homeBase': {'lat': 23.79, 'lng': 90.4},
      'workingRadiusM': 12000,
    });
    h.http.onPut(
      '/v1/provider/enrolment/services',
      (s) => s.reply(409, apiError('CONFLICT')),
    );
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    // The failure waits behind the "Saved" snack bar.
    await tester.pump(const Duration(seconds: 5));
    await h.settle(tester);
    expect(
      find.text('This was already changed. Refresh and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('a missing home base is taken from the GPS', (tester) async {
    final h = await start(tester);
    h.http
      ..onGet(
        '/v1/provider/profile',
        (s) => s.reply(200, profile(homeBase: false)),
      )
      ..onGet(
        '/v1/provider/catalog',
        (s) => s.reply(500, apiError('INTERNAL')),
      );
    await h.pumpApp(tester, Routes.profilePage('services'));
    expect(find.text('Something went wrong'), findsOneWidget);
    h.http.onGet('/v1/provider/catalog', (s) => s.reply(200, catalog()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('8 km'), findsOneWidget);
    h.location.point = null;
    await tester.tap(find.text('Use my location'));
    await h.settle(tester);
    expect(find.text('Turn on location and try again.'), findsOneWidget);
    h.location.point = const GeoPoint(23.8, 90.41);
    await tester.tap(find.text('Use my location'));
    await h.settle(tester);
    expect(find.text('Set'), findsOneWidget);
  });

  testWidgets('language is kept on the phone and the profile', (tester) async {
    final h = await start(tester);
    h.http.onPut(
      '/v1/provider/profile',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await h.pumpApp(tester, Routes.profilePage('language'));
    await tester.tap(find.text('বাংলা'));
    await h.settle(tester);
    expect(h.services.prefs.string(Prefs.languageKey), 'bn');
    expect(h.bodyOf('/v1/provider/profile'), {'language': 'bn'});
    expect(find.textContaining('এই ফোনে সংরক্ষিত'), findsOneWidget);
    h.http.onPut('/v1/provider/profile', (s) => s.reply(200, profile()));
    await tester.tap(find.text('English'));
    await h.settle(tester);
    expect(h.services.prefs.string(Prefs.languageKey), 'en');
    expect(find.textContaining('Saved on this phone'), findsNothing);
    await h.go(tester, Routes.profile);
    h.services.locale.select(const Locale('bn'));
    await h.settle(tester);
    final profilePuts = h.sent.where(
      (o) => o.method == 'PUT' && o.path == '/v1/provider/profile',
    );
    expect(profilePuts, hasLength(2));
  });

  testWidgets('help expands topics and calls support', (tester) async {
    final h = await start(tester);
    await h.pumpApp(tester, Routes.profilePage('help'));
    await tester.tap(find.text('What is the start code?'));
    await h.settle(tester);
    expect(find.textContaining('4-digit code'), findsOneWidget);
    await tester.tap(find.text('Call PAO support'));
    await h.settle(tester);
    expect(h.launched.single.scheme, 'tel');
  });
}
