import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_e2e/pao_e2e.dart';

/// Signs in from the first launch: onboarding, phone (M03) and the code read
/// from the stack's SMS capture (M04).
Future<void> signInWithOtp(
  WidgetTester tester,
  StackClient stack,
  String phone,
) async {
  await tapText(tester, 'Skip');
  await typeInto(tester, 'Mobile number', phone);
  await tapText(tester, 'Send code');
  await pumpUntil(tester, find.text('Enter the 6-digit code'));
  await enterCode(tester, await stack.lastCode(phone));
}

/// Saves the current wizard step.
Future<void> _save(WidgetTester tester) => tapText(tester, 'Save and continue');

Future<void> _onStep(WidgetTester tester, String title) =>
    pumpUntil(tester, find.widgetWithText(AppBar, title));

/// Opens the wizard from the verification screen the gate shows a new
/// provider, unless the app went straight to the first step.
Future<void> openWizard(WidgetTester tester) async {
  const resume = 'Continue enrolment';
  await pumpUntil(
    tester,
    find.byWidgetPredicate(
      (w) =>
          w is Text && (w.data == resume || w.data == 'Personal information'),
    ),
  );
  if (find.text(resume).evaluate().isNotEmpty) await tapText(tester, resume);
}

/// Picks [typed] (MM/DD/YYYY) in the date picker opened from [field].
Future<void> _pickDate(WidgetTester tester, String field, String typed) async {
  await tapText(tester, field);
  await tapOn(tester, find.byTooltip('Switch to input'));
  await tester.enterText(
    find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)),
    typed,
  );
  await tapText(tester, 'OK');
}

/// Takes the photo of the next empty slot and waits for its upload.
Future<void> _photo(WidgetTester tester, int uploaded) async {
  await tapText(tester, 'Take photo');
  await pumpUntil(tester, find.text('Uploaded'), atLeast: uploaded);
}

/// Fills M05–M07 from the wizard's first step.
Future<void> enrolProfile(WidgetTester tester) async {
  await _onStep(tester, 'Personal information');
  await typeInto(tester, 'Full name (as on your NID)', 'Rahim Uddin');
  await _pickDate(tester, 'Select a date', '04/12/1990');
  await tapText(tester, 'Male');
  await typeInto(tester, 'Present address', 'House 12, Road 5, Banani');
  await typeInto(tester, 'Permanent address', 'Cumilla Sadar, Cumilla');
  await _save(tester);
  await _onStep(tester, 'Your services');
  await tapText(tester, 'Electrician');
  await _save(tester);
  await _onStep(tester, 'Service area');
  await tapText(tester, 'Use my current location');
  await pumpUntil(tester, find.textContaining('Home base:'));
  await _save(tester);
}

/// Fills M08–M11: NID with both photos, selfie, police clearance, and skips
/// the optional skill proof.
Future<void> enrolDocuments(WidgetTester tester, String nid) async {
  await _onStep(tester, 'National ID');
  await typeInto(tester, 'NID number', nid);
  await _photo(tester, 1);
  await _photo(tester, 2);
  await _save(tester);
  await _onStep(tester, 'Live selfie');
  await _photo(tester, 1);
  await _save(tester);
  await _onStep(tester, 'Police clearance');
  await _photo(tester, 1);
  await tapText(tester, 'Select a date');
  await tapText(tester, 'OK');
  await _save(tester);
  await _onStep(tester, 'Skill proof');
  await tapText(tester, 'Skip for now');
}

/// Fills M12–M13, confirming the contact with the texted code, and submits.
Future<void> enrolContactAndSubmit(
  WidgetTester tester,
  StackClient stack,
  String contact,
) async {
  await _onStep(tester, 'Emergency contact');
  await typeInto(tester, 'Name', 'Karim Uddin');
  await typeInto(tester, 'Relation', 'Brother');
  await typeInto(tester, 'Mobile number', contact);
  await tapText(tester, 'Send code');
  await pumpUntil(tester, find.textContaining('Enter the code we sent'));
  await enterCode(tester, await stack.lastCode(contact));
  await _onStep(tester, 'Code of conduct');
  await tapText(tester, 'I have read and accept the code of conduct.');
  await _save(tester);
  await _onStep(tester, 'Review and submit');
  await tapText(tester, 'Submit for verification');
}
