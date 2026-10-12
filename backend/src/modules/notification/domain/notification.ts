/** Why a notification request failed; the HTTP adapter maps them to API errors. */
export const NotificationReasons = {
  NotFound: 'notification.not_found',
  Invalid: 'notification.invalid',
} as const;

/** The two apps; device tokens and inboxes are kept per app. */
export const App = {
  Customer: 'customer',
  Partner: 'partner',
} as const;

/** An app a notification goes to. */
export type App = (typeof App)[keyof typeof App];

/** Reports whether `app` names one of the two apps. */
export function isApp(app: string): app is App {
  return app === App.Customer || app === App.Partner;
}

/** One inbox entry. */
export interface Notification {
  readonly id: string;
  readonly recipientId: string;
  readonly app: App;
  /** The template, which names the event that caused it. */
  readonly type: string;
  readonly title: string;
  readonly body: string;
  readonly bookingId: string | null;
  readonly dedupeKey: string;
  readonly read: boolean;
  readonly createdAt: Date;
}

/** What a device receives. */
export interface Push {
  readonly title: string;
  readonly body: string;
  readonly data: Readonly<Record<string, string>>;
}
