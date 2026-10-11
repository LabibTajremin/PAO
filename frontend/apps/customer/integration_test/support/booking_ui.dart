import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_ui/pao_ui.dart';

/// Signs a new customer up from the first launch: onboarding, phone (C03),
/// the code from the stack's SMS capture (C04), profile (C05) and the address
/// from the device position (C06), ending on home.
Future<void> signUp(
  WidgetTester tester,
  StackClient stack,
  String phone,
) async {
  await tapText(tester, 'Skip');
  await typeInto(tester, 'Mobile number', phone);
  await tapText(tester, 'Send code');
  await pumpUntil(tester, find.text('Enter the 6-digit code'));
  await enterCode(tester, await stack.lastCode(phone));
  await typeInto(tester, 'Your name', 'Nusrat Jahan');
  await tapText(tester, 'Continue');
  await tapText(tester, 'Allow location access');
  await typeInto(tester, 'House and road', 'House 12, Road 5, Banani');
  await tapText(tester, 'Save address');
  await pumpUntil(tester, find.text('Services'));
}

/// From home, chooses one ceiling fan installation (C09) and opens the
/// provider list (C10).
Future<void> chooseService(WidgetTester tester) async {
  await tapText(tester, 'Electrical');
  final tile = find.ancestor(
    of: find.text('Ceiling fan installation'),
    matching: find.byType(PaoCard),
  );
  await tapOn(
    tester,
    find.descendant(of: tile, matching: find.byIcon(Icons.add)),
  );
  await tapText(tester, 'See providers');
}

/// Books the provider named [name] as soon as possible (C11, C12) and waits
/// for the request screen (C13).
Future<void> bookAsap(WidgetTester tester, String name) async {
  await tapOn(tester, find.text(name));
  await tapText(tester, 'Book $name');
  await tapText(tester, 'As soon as possible');
  await tapOn(tester, find.textContaining('Confirm booking ·'));
  await pumpUntil(tester, find.text('Waiting for $name to accept'));
}

/// The start code the live screen (C14) shows.
Future<String> startCode(WidgetTester tester) async {
  final code = find.byKey(const Key('C14.startCode'));
  await pumpUntil(tester, code);
  return tester.widget<Text>(code).data!;
}
