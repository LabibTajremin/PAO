import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/auth/presentation/otp_page.dart';
import 'package:pao_customer/features/auth/presentation/phone_page.dart';
import 'package:pao_customer/features/auth/presentation/profile_setup_page.dart';
import 'package:pao_customer/features/home/presentation/home_page.dart';
import 'package:pao_customer/features/home/presentation/services_page.dart';
import 'package:pao_customer/features/location/presentation/address_page.dart';
import 'package:pao_customer/features/onboarding/presentation/onboarding_page.dart';
import 'package:pao_customer/features/providers/presentation/provider_profile_page.dart';
import 'package:pao_customer/features/providers/presentation/providers_page.dart';
import 'package:pao_customer/features/providers/presentation/reviews_page.dart';
import 'package:pao_customer/features/search/presentation/search_page.dart';
import 'package:pao_customer/features/service/presentation/service_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../support/harness.dart';

void main() {
  testWidgets('signed-out customers land on phone entry', (tester) async {
    final h = await Harness.create();
    await h.pumpApp(tester);
    expect(find.byType(PhonePage), findsOneWidget);
  });

  testWidgets('a signed-in customer reaches every screen', (tester) async {
    final h = await Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester);
    final pages = <String, Type>{
      Routes.onboarding: OnboardingPage,
      '${Routes.otp}?phone=01712345678': OtpPage,
      Routes.profileSetup: ProfileSetupPage,
      Routes.location: AddressPage,
      Routes.services: ServicesPage,
      Routes.search: SearchPage,
      Routes.serviceOf('s1'): ServicePage,
      Routes.providersOf('s1'): ProvidersPage,
      Routes.providerOf('p1'): ProviderProfilePage,
      Routes.providerReviewsOf('p1'): ReviewsPage,
      Routes.book: PlaceholderPage,
      for (final part in [
        '',
        'waiting',
        'confirmed',
        'live',
        'extras',
        'cancel',
        'completed',
        'rate',
        'receipt',
        'report',
      ])
        Routes.booking('b1', part): PlaceholderPage,
      Routes.bookings: PlaceholderPage,
      Routes.notifications: PlaceholderPage,
      Routes.account: PlaceholderPage,
      Routes.accountPage('addresses'): PlaceholderPage,
      Routes.addressNew: AddressPage,
      Routes.addressEdit('a1'): AddressPage,
    };
    for (final MapEntry(key: path, value: type) in pages.entries) {
      await h.go(tester, path);
      expect(find.byType(type), findsOneWidget, reason: path);
    }
    await h.go(tester, Routes.otp);
    expect(find.byType(OtpPage), findsOneWidget);
  });

  testWidgets('tabs switch branches; denied and expired screens', (
    tester,
  ) async {
    final h = await Harness.create();
    await h.signIn(tester, screens: ['C07']);
    await h.pumpApp(tester);
    expect(find.byType(HomePage), findsOneWidget);
    await tester.tap(find.text('Bookings'));
    await h.settle(tester);
    expect(find.text('You do not have access to this screen.'), findsOneWidget);
    await h.services.sessions.signOut(expired: true);
    await h.settle(tester);
    await tester.tap(find.text('Continue'));
    await h.settle(tester);
    expect(find.byType(PhonePage), findsOneWidget);
  });
}
