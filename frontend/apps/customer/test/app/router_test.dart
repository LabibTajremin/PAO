import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/account/presentation/account_page.dart';
import 'package:pao_customer/features/account/presentation/addresses_page.dart';
import 'package:pao_customer/features/account/presentation/delete_account_page.dart';
import 'package:pao_customer/features/account/presentation/edit_profile_page.dart';
import 'package:pao_customer/features/account/presentation/help_page.dart';
import 'package:pao_customer/features/account/presentation/language_page.dart';
import 'package:pao_customer/features/account/presentation/legal_page.dart';
import 'package:pao_customer/features/auth/presentation/otp_page.dart';
import 'package:pao_customer/features/auth/presentation/phone_page.dart';
import 'package:pao_customer/features/auth/presentation/profile_setup_page.dart';
import 'package:pao_customer/features/booking/presentation/confirmed_page.dart';
import 'package:pao_customer/features/booking/presentation/setup_page.dart';
import 'package:pao_customer/features/booking/presentation/waiting_page.dart';
import 'package:pao_customer/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_customer/features/bookings/presentation/bookings_page.dart';
import 'package:pao_customer/features/bookings/presentation/receipt_page.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_page.dart';
import 'package:pao_customer/features/live/presentation/completed_page.dart';
import 'package:pao_customer/features/live/presentation/extras_page.dart';
import 'package:pao_customer/features/live/presentation/live_page.dart';
import 'package:pao_customer/features/notifications/presentation/notifications_page.dart';
import 'package:pao_customer/features/onboarding/presentation/onboarding_page.dart';
import 'package:pao_customer/features/rating/presentation/rating_page.dart';
import 'package:pao_customer/features/report/presentation/report_page.dart';
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
      Routes.location: PlaceholderPage,
      Routes.services: PlaceholderPage,
      Routes.search: PlaceholderPage,
      Routes.serviceOf('s1'): PlaceholderPage,
      Routes.providersOf('s1'): PlaceholderPage,
      Routes.providerOf('p1'): PlaceholderPage,
      Routes.book: SetupPage,
      Routes.booking('b1', 'waiting'): WaitingPage,
      Routes.booking('b1', 'confirmed'): ConfirmedPage,
      Routes.booking('b1', 'live'): LivePage,
      Routes.booking('b1', 'extras'): ExtrasPage,
      Routes.booking('b1', 'cancel'): CancelPage,
      Routes.booking('b1', 'completed'): CompletedPage,
      Routes.booking('b1', 'rate'): RatingPage,
      Routes.booking('b1'): BookingDetailPage,
      Routes.booking('b1', 'receipt'): ReceiptPage,
      Routes.booking('b1', 'report'): ReportPage,
      Routes.bookings: BookingsPage,
      Routes.notifications: NotificationsPage,
      Routes.account: AccountPage,
      Routes.accountPage('profile'): EditProfilePage,
      Routes.accountPage('addresses'): AddressesPage,
      Routes.accountPage('language'): LanguagePage,
      Routes.accountPage('help'): HelpPage,
      Routes.accountPage('delete'): DeleteAccountPage,
      Routes.legal: LegalPage,
      Routes.addressNew: PlaceholderPage,
      Routes.addressEdit('a1'): PlaceholderPage,
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
    expect(find.text('C07'), findsOneWidget);
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
