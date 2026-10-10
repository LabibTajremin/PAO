/// Route paths of the customer app (docs/build/05-screens.md, customer table).
abstract final class Routes {
  /// C01.
  static const splash = '/';

  /// C02, C31, C32.
  static const onboarding = '/onboarding';

  /// C03.
  static const phone = '/auth/phone';

  /// C04, C33.
  static const otp = '/auth/otp';

  /// C05.
  static const profileSetup = '/auth/profile';

  /// C06, C34.
  static const location = '/auth/location';

  /// C63.
  static const welcomeBack = '/auth/welcome-back';

  /// Role may not open a screen.
  static const denied = '/denied';

  /// C07, C35.
  static const home = '/home';

  /// C37.
  static const services = '/services';

  /// C08, C38.
  static const search = '/search';

  /// C09, C43, C44.
  static const service = '/services/:id';

  /// C10, C39, C40.
  static const providers = '/services/:id/providers';

  /// C11, C41, C42.
  static const provider = '/providers/:id';

  /// C12, C45, C46.
  static const book = '/book';

  /// C18, C18b, C58.
  static const bookings = '/bookings';

  /// C21, C59, C60.
  static const notifications = '/notifications';

  /// C22, C30.
  static const account = '/account';

  /// C28, also linked from sign-in.
  static const legal = '/account/legal';

  /// A service's detail.
  static String serviceOf(String id) => '/services/$id';

  /// Providers offering a service.
  static String providersOf(String serviceId) =>
      '/services/$serviceId/providers';

  /// A provider's public profile.
  static String providerOf(String id) => '/providers/$id';

  /// A booking screen; [part] is `waiting`, `confirmed`, `live`, `extras`,
  /// `cancel`, `completed`, `rate`, `receipt` or `report`, or empty for the
  /// detail.
  static String booking(String id, [String part = '']) =>
      part.isEmpty ? '/bookings/$id' : '/bookings/$id/$part';

  /// C25, adding an address.
  static const addressNew = '/account/addresses/new';

  /// C25, editing a saved address.
  static String addressEdit(String id) => '/account/addresses/$id';

  /// An account sub-page such as `addresses`.
  static String accountPage(String page) => '/account/$page';

  /// Screen ID per route, checked against the account's screens.
  static const Map<String, String> screens = {
    home: 'C07',
    services: 'C37',
    search: 'C08',
    service: 'C09',
    providers: 'C10',
    provider: 'C11',
    book: 'C12',
    '/bookings/:id/waiting': 'C13',
    '/bookings/:id/confirmed': 'C48',
    '/bookings/:id/live': 'C14',
    '/bookings/:id/extras': 'C15',
    '/bookings/:id/cancel': 'C52',
    '/bookings/:id/completed': 'C16',
    '/bookings/:id/rate': 'C17',
    bookings: 'C18',
    '/bookings/:id': 'C19',
    '/bookings/:id/receipt': 'C64',
    '/bookings/:id/report': 'C20',
    notifications: 'C21',
    account: 'C22',
    '/account/profile': 'C23',
    '/account/addresses': 'C24',
    addressNew: 'C25',
    '/account/addresses/:id': 'C25',
    '/account/language': 'C26',
    '/account/help': 'C27',
    '/account/legal': 'C28',
    '/account/delete': 'C29',
    profileSetup: 'C05',
    location: 'C06',
  };

  /// Open without signing in.
  static const Set<String> public = {
    splash,
    onboarding,
    phone,
    otp,
    welcomeBack,
    legal,
  };

  /// Open to a signed-in account that has no profile yet.
  static const Set<String> beforeProfile = {...public, denied, profileSetup};
}
