// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AdminL10nEn extends AdminL10n {
  AdminL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PAO Admin';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navVerification => 'Verification';

  @override
  String get navLevel2 => 'Level 2 sessions';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navProviders => 'Providers';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navComplaints => 'Complaints';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginTitle => 'Sign in to PAO Admin';

  @override
  String get loginEmail => 'Work email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginEnrolBody =>
      'First sign-in: add this key to your authenticator app.';

  @override
  String get loginCodeBody =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get loginBack => 'Use another account';

  @override
  String get passwordTitle => 'Choose a new password';

  @override
  String get passwordBody =>
      'Replace the temporary password from your invitation before you continue.';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password (at least 12 characters)';

  @override
  String get passwordRepeat => 'Repeat the new password';

  @override
  String get passwordTooShort =>
      'The new password needs at least 12 characters.';

  @override
  String get passwordMismatch => 'The two new passwords are not the same.';

  @override
  String get reasonLabel => 'Reason';

  @override
  String reasonTooShort(int count) {
    return 'Write at least $count characters.';
  }
}
