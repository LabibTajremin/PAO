/// Route paths of the partner app (docs/build/05-screens.md, partner table).
abstract final class Routes {
  /// M01.
  static const splash = '/';

  /// M02.
  static const onboarding = '/onboarding';

  /// M03.
  static const phone = '/auth/phone';

  /// M04.
  static const otp = '/auth/otp';

  /// Session expired.
  static const welcomeBack = '/auth/welcome-back';

  /// Role may not open a screen.
  static const denied = '/denied';

  /// M05–M13.
  static const enrol = '/enrol/:step';

  /// M14.
  static const verification = '/verification';

  /// M15.
  static const home = '/home';

  /// M16.
  static const request = '/requests/:id';

  /// M23.
  static const jobs = '/jobs';

  /// M26, M27.
  static const earnings = '/earnings';

  /// M28.
  static const profile = '/profile';

  /// Notification inbox.
  static const notifications = '/notifications';

  /// One enrolment step.
  static String enrolStep(String step) => '/enrol/$step';

  /// An incoming request.
  static String requestOf(String id) => '/requests/$id';

  /// A job screen; [part] is `live`, `start`, `extras`, `complete`, `rate` or
  /// `report`, or empty for the detail.
  static String job(String id, [String part = '']) =>
      part.isEmpty ? '/jobs/$id' : '/jobs/$id/$part';

  /// A profile sub-page such as `documents`.
  static String profilePage(String page) => '/profile/$page';

  /// Screen ID per route, checked against the account's screens.
  static const Map<String, String> screens = {
    home: 'M15',
    request: 'M16',
    '/jobs/:id/live': 'M17',
    '/jobs/:id/start': 'M18',
    '/jobs/:id/extras': 'M19',
    '/jobs/:id/complete': 'M20',
    '/jobs/:id/rate': 'M21',
    jobs: 'M23',
    '/jobs/:id': 'M24',
    '/jobs/:id/report': 'M25',
    earnings: 'M26',
    profile: 'M28',
    '/profile/public': 'M29',
    '/profile/reviews': 'M30',
    '/profile/documents': 'M31',
    '/profile/level': 'M32',
    '/profile/services': 'M33',
    '/profile/language': 'M34',
    '/profile/help': 'M35',
    enrol: 'M05',
    verification: 'M14',
  };

  /// Open without signing in.
  static const Set<String> public = {
    splash,
    onboarding,
    phone,
    otp,
    welcomeBack,
  };

  /// Open before Level 1 (PRD §8.5).
  static const Set<String> beforeLevel1 = {
    ...public,
    denied,
    enrol,
    verification,
    notifications,
    '/profile/language',
    '/profile/help',
  };
}
