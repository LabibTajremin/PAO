import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/verification/presentation/verification_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'enrolment_repository_test.dart' show catalogJson;
import 'fakes.dart';

const _base = '/v1/provider/enrolment';

Future<Harness> _open(
  WidgetTester tester,
  String step, {
  Set<EnrolStep> done = const {},
  bool submitted = false,
}) async {
  final h = await Harness.create();
  await h.signIn(tester, cleared: false);
  h.http.onGet(
    _base,
    (s) => s.reply(200, enrolmentJson(done: done, submitted: submitted)),
  );
  await h.pumpApp(tester, Routes.enrolStep(step));
  await h.settle(tester);
  return h;
}

void _onPut(Harness h, String path, Set<EnrolStep> done) => h.http.onPut(
  '$_base/$path',
  (s) => s.reply(200, enrolmentJson(done: done)),
  data: Matchers.any,
);

// Some steps load more once they appear, so settle twice.
Future<void> _tap(Harness h, WidgetTester tester, String text) async {
  await tapIn(tester, find.text(text));
  await h.settle(tester);
  await h.settle(tester);
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.widgetWithText(PaoTextField, label),
    matching: find.byType(TextField),
  );
  await tester.scrollUntilVisible(
    field,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(field, text);
}

void main() {
  testWidgets('a failed load can be retried; it resumes at the first gap', (
    tester,
  ) async {
    final h = await Harness.create();
    await h.signIn(tester, cleared: false);
    h.http.onGet(_base, (s) => s.reply(503, apiError('INTERNAL')));
    await h.pumpApp(tester, Routes.enrolStep('start'));
    expect(find.text('Our service had a problem. Please try again.'), findsOne);
    h.http.onGet(
      _base,
      (s) => s.reply(200, enrolmentJson(done: {EnrolStep.personal})),
    );
    h.http.onGet('/v1/provider/catalog', (s) => s.reply(200, catalogJson()));
    await _tap(h, tester, 'Try again');
    expect(find.text('Your services'), findsOne);
    expect(find.text('Step 2 of 9'), findsOne);
    await _tap(h, tester, 'Back');
    expect(find.text('Personal information'), findsOne);
  });

  testWidgets('personal info checks the age rule, then saves', (tester) async {
    final h = await _open(tester, 'personal');
    await _tap(h, tester, 'Save and continue');
    expect(find.text('Enter your full name as written on your NID.'), findsOne);
    expect(find.text('Choose your gender.'), findsOne);
    expect(find.text('Enter a full address.'), findsNWidgets(2));
    await _type(tester, 'Full name (as on your NID)', 'Rahim Uddin');
    await _tap(h, tester, 'Select a date');
    await _tap(h, tester, 'OK');
    expect(find.text('You must be at least 18 years old.'), findsOne);
    await _tap(h, tester, 'Oct 9, 2026');
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      '04/12/1990',
    );
    await _tap(h, tester, 'OK');
    await _tap(h, tester, 'Male');
    await _type(tester, 'Present address', 'House 4, Banani');
    await _type(tester, 'Permanent address', 'Sherpur, Bogura');
    _onPut(h, 'personal', {EnrolStep.personal});
    h.http.onGet('/v1/provider/catalog', (s) => s.reply(200, catalogJson()));
    await _tap(h, tester, 'Save and continue');
    expect(h.bodyOf('$_base/personal'), {
      'fullName': 'Rahim Uddin',
      'dateOfBirth': '1990-04-12',
      'gender': 'male',
      'presentAddress': 'House 4, Banani',
      'permanentAddress': 'Sherpur, Bogura',
    });
    expect(find.text('Your services'), findsOne);
  });

  testWidgets('services: retry, choose, set experience and save', (
    tester,
  ) async {
    final h = await Harness.create();
    await h.signIn(tester, cleared: false);
    h.http
      ..onGet(_base, (s) => s.reply(200, enrolmentJson()))
      ..onGet('/v1/provider/catalog', (s) => s.reply(503, apiError('X')));
    await h.pumpApp(tester, Routes.enrolStep('services'));
    await h.settle(tester);
    h.http.onGet('/v1/provider/catalog', (s) => s.reply(200, catalogJson()));
    await _tap(h, tester, 'Try again');
    await _tap(h, tester, 'Save and continue');
    expect(find.text('Choose at least one service.'), findsOne);
    await _tap(h, tester, 'Electrician s1');
    await _tap(h, tester, 'Electrician s1');
    await _tap(h, tester, 'Electrician s1');
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    _onPut(h, 'services', {EnrolStep.services});
    await _tap(h, tester, 'Save and continue');
    expect(h.bodyOf('$_base/services'), {
      'serviceIds': ['s1'],
      'experienceYears': 2,
    });
    expect(find.text('Service area'), findsOne);
  });

  testWidgets('services: an empty catalog says so', (tester) async {
    final h = await Harness.create();
    await h.signIn(tester, cleared: false);
    h.http
      ..onGet(_base, (s) => s.reply(200, enrolmentJson()))
      ..onGet(
        '/v1/provider/catalog',
        (s) => s.reply(200, {'version': 1, 'categories': <Object?>[]}),
      );
    await h.pumpApp(tester, Routes.enrolStep('services'));
    await h.settle(tester);
    expect(find.text('No services are open for enrolment yet.'), findsOne);
  });

  testWidgets('area: locate, set the radius and save', (tester) async {
    final h = await _open(tester, 'area');
    await _tap(h, tester, 'Save and continue');
    expect(find.text('Set your home base first.'), findsOne);
    h.location.point = null;
    await _tap(h, tester, 'Use my current location');
    expect(
      find.text('Turn on location and allow PAO Partner to use it.'),
      findsOne,
    );
    h.location.point = const GeoPoint(23.794, 90.407);
    await _tap(h, tester, 'Use my current location');
    expect(find.text('Home base: 23.7940, 90.4070'), findsOne);
    await tester.drag(find.byType(Slider), const Offset(-1000, 0));
    await tester.pumpAndSettle();
    expect(find.text('Working radius: 1 km'), findsOne);
    _onPut(h, 'area', {EnrolStep.area});
    await _tap(h, tester, 'Save and continue');
    expect(h.bodyOf('$_base/area'), {
      'homeBase': {'lat': 23.794, 'lng': 90.407},
      'workingRadiusM': 1000,
    });
    expect(find.text('National ID'), findsOne);
    when(
      () => h.picker.pickImage(
        source: ImageSource.camera,
        // The stub must name the argument PhotoSource passes to match it.
        // ignore: avoid_redundant_argument_values
        preferredCameraDevice: CameraDevice.rear,
      ),
    ).thenAnswer((_) async => null);
    await _tap(h, tester, 'Take photo');
    expect(find.text('Uploading 0%'), findsNothing);
  });

  testWidgets('contact code, code of conduct and submission', (tester) async {
    final before = allRequired.difference({
      EnrolStep.emergencyContact,
      EnrolStep.codeOfConduct,
    });
    final h = await _open(tester, 'emergency_contact', done: before);
    await _tap(h, tester, 'Send code');
    expect(find.text('Enter their name.'), findsOne);
    expect(find.text('Enter how you are related.'), findsOne);
    expect(find.text('Enter an 11-digit Bangladeshi mobile number.'), findsOne);
    await _type(tester, 'Name', 'Karim');
    await _type(tester, 'Relation', 'Brother');
    await _type(tester, 'Mobile number', '1812345678');
    _onPut(h, 'emergency-contact', before);
    await _tap(h, tester, 'Send code');
    expect(find.text('Enter the code we sent to 01812345678.'), findsOne);
    await _tap(h, tester, 'Change contact');
    await _tap(h, tester, 'Send code');
    await _tap(h, tester, 'Send the code again');
    h.http.onPost(
      '$_base/emergency-contact/verify',
      (s) => s.reply(422, apiError('OTP_INVALID')),
      data: Matchers.any,
    );
    await tester.enterText(find.byType(TextField), '000000');
    await h.settle(tester);
    expect(find.text('That code is not right.'), findsOne);
    h.http.onPost(
      '$_base/emergency-contact/verify',
      (s) => s.reply(
        200,
        enrolmentJson(done: {...before, EnrolStep.emergencyContact}),
      ),
      data: Matchers.any,
    );
    await tester.enterText(find.byType(TextField), '123456');
    await h.settle(tester);
    expect(find.text('Code of conduct'), findsOne);
    await _tap(h, tester, 'I have read and accept the code of conduct.');
    _onPut(h, 'code-of-conduct', allRequired);
    await _tap(h, tester, 'Save and continue');
    expect(find.text('Review and submit'), findsOne);
    expect(find.text('Optional'), findsOne);
    h.http.onPost(
      '$_base/submit',
      (s) => s.reply(200, verification(cleared: false, level: 0)),
    );
    await _tap(h, tester, 'Submit for verification');
    expect(find.byType(VerificationPage), findsOne);
  });

  testWidgets('skill proof can be skipped', (tester) async {
    final h = await _open(tester, 'skill_proof');
    await _tap(h, tester, 'Skip for now');
    expect(find.text('Emergency contact'), findsOne);
  });

  testWidgets('a submitted enrolment links back to verification', (
    tester,
  ) async {
    final h = await _open(tester, 'review', done: allRequired, submitted: true);
    expect(find.text('Your enrolment has been submitted.'), findsOne);
    expect(find.text('Optional'), findsOne);
    await _tap(h, tester, 'See verification status');
    expect(find.byType(VerificationPage), findsOne);
    await h.go(tester, Routes.enrolStep('review'));
    await _tap(h, tester, 'Live selfie');
    expect(find.text('Step 5 of 9'), findsOne);
    await _tap(h, tester, 'Back');
    expect(find.text('Step 4 of 9'), findsOne);
    await h.go(tester, Routes.verification);
    expect(find.byType(VerificationPage), findsOne);
  });
}
