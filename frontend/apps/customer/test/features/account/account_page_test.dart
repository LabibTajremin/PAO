import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/account/presentation/account_page.dart';
import 'package:pao_customer/features/account/presentation/addresses_page.dart';
import 'package:pao_customer/features/account/presentation/delete_account_page.dart';
import 'package:pao_customer/features/account/presentation/edit_profile_page.dart';
import 'package:pao_customer/features/account/presentation/help_page.dart';
import 'package:pao_customer/features/account/presentation/language_page.dart';
import 'package:pao_customer/features/account/presentation/legal_page.dart';
import 'package:pao_customer/features/auth/presentation/phone_page.dart';

import '../../support/harness.dart';

Future<Harness> _start(WidgetTester tester) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  await h.pumpApp(tester, Routes.account);
  return h;
}

void main() {
  testWidgets('the account tab shows who is signed in and opens each page', (
    tester,
  ) async {
    final h = await _start(tester);
    expect(find.text('Nusrat Jahan'), findsOneWidget);
    expect(find.text('+8801712345678'), findsOneWidget);
    final pages = {
      'Edit profile': EditProfilePage,
      'Saved addresses': AddressesPage,
      'Language': LanguagePage,
      'Help & support': HelpPage,
      'Terms & privacy': LegalPage,
      'Delete account': DeleteAccountPage,
    };
    for (final MapEntry(key: label, value: type) in pages.entries) {
      await tester.tap(find.text(label));
      await h.settle(tester);
      expect(find.byType(type), findsOneWidget, reason: label);
      await tester.pageBack();
      await h.settle(tester);
    }
    h.services.gate.clear();
    await h.settle(tester);
    expect(find.text('Nusrat Jahan'), findsNothing);
  });

  testWidgets('log out asks first, then signs out even offline (C30)', (
    tester,
  ) async {
    final h = await _start(tester);
    await tester.tap(find.text('Log out'));
    await h.settle(tester);
    expect(find.text('Log out of PAO?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(find.byType(AccountPage), findsOneWidget);
    await tester.tap(find.text('Log out'));
    await h.settle(tester);
    await tester.tap(find.text('Log out').last);
    await h.settle(tester);
    expect(h.sent.any((o) => o.path == '/v1/auth/logout'), isTrue);
    expect(h.services.sessions.signedIn, isFalse);
    expect(h.services.gate.profile, isNull);
    expect(find.byType(PhonePage), findsOneWidget);
  });

  testWidgets('edit profile keeps the language and saves name and photo', (
    tester,
  ) async {
    final h = await _start(tester);
    await h.go(tester, Routes.accountPage('profile'));
    expect(find.widgetWithText(TextField, 'Nusrat Jahan'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'N');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.text('Enter a name of 2 to 80 characters.'), findsOneWidget);
    when(() => h.picker.pickImage(source: ImageSource.gallery))
        .thenAnswer((_) async => XFile.fromData(tinyPng));
    await tester.tap(find.text('Change photo'));
    await h.settle(tester);
    h.http.onPost(
      '/v1/customer/uploads',
      (s) => s.reply(422, apiError('UPLOAD_INVALID')),
    );
    await tester.enterText(find.byType(TextField), 'Nusrat J.');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(
      find.text('This file cannot be used. Try another photo.'),
      findsOneWidget,
    );
    await h.go(tester, Routes.account);
    await h.go(tester, Routes.accountPage('profile'));
    h.http.onPut(
      '/v1/customer/profile',
      (s) => s.reply(200, profile(name: 'Nusrat J.')),
    );
    await tester.enterText(find.byType(TextField), 'Nusrat J.');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(h.bodyOf('/v1/customer/profile'), {
      'name': 'Nusrat J.',
      'language': 'en',
    });
    expect(find.text('Profile saved'), findsOneWidget);
    expect(find.text('Nusrat J.'), findsOneWidget);
  });

  testWidgets('without a loaded profile the app language is saved', (
    tester,
  ) async {
    final h = await _start(tester);
    h.services.gate.clear();
    h.services.locale.select(const Locale('bn'));
    await h.go(tester, Routes.accountPage('profile'));
    h.http.onPut('/v1/customer/profile', (s) => s.reply(200, profile()));
    await tester.enterText(find.byType(TextField), 'Rina');
    await tester.tap(find.text('সংরক্ষণ করুন'));
    await h.settle(tester);
    expect((h.bodyOf('/v1/customer/profile')! as Map)['language'], 'bn');
  });
}
