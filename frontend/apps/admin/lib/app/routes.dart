/// Route paths of the admin panel (docs/build/05-screens.md, admin table).
abstract final class Routes {
  /// A01.
  static const login = '/login';

  /// A01, replacing the temporary password.
  static const password = '/login/password';

  /// Session expired.
  static const welcomeBack = '/login/welcome-back';

  /// Role may not open a screen.
  static const denied = '/denied';

  /// A02.
  static const dashboard = '/dashboard';

  /// A03.
  static const catalog = '/catalog';

  /// A04.
  static const service = '/catalog/services/:id';

  /// A05.
  static const verification = '/verification';

  /// A06.
  static const review = '/verification/:providerId';

  /// A07.
  static const level2 = '/level2';

  /// A08.
  static const providers = '/providers';

  /// A09.
  static const customers = '/customers';

  /// A10.
  static const bookings = '/bookings';

  /// A11.
  static const complaints = '/complaints';

  /// A12.
  static const settings = '/settings';

  /// A service in the editor.
  static String serviceOf(String id) => '/catalog/services/$id';

  /// A provider's verification review.
  static String reviewOf(String providerId) => '/verification/$providerId';

  /// One record under a list route, e.g. `detail(providers, id)`.
  static String detail(String list, String id) => '$list/$id';

  /// A settings tab: `admins`, `roles` or `audit`; empty for settings.
  static String settingsTab(String tab) =>
      tab.isEmpty ? settings : '$settings/$tab';

  /// Screen ID per route, checked against the admin's screens.
  static const Map<String, String> screens = {
    dashboard: 'A02',
    catalog: 'A03',
    service: 'A04',
    verification: 'A05',
    review: 'A06',
    level2: 'A07',
    providers: 'A08',
    '/providers/:id': 'A08',
    customers: 'A09',
    '/customers/:id': 'A09',
    bookings: 'A10',
    '/bookings/:id': 'A10',
    complaints: 'A11',
    '/complaints/:id': 'A11',
    settings: 'A12',
    '/settings/:tab': 'A12',
  };

  /// Open without signing in.
  static const Set<String> public = {login, welcomeBack};
}
