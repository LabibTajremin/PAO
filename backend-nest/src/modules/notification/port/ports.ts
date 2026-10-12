import { type App, type Notification, type Push } from '../domain/notification';

/** A keyset position over (created_at, id); `limit` includes the look-ahead row. */
export interface Page {
  readonly before?: { readonly createdAt: Date; readonly id: string };
  readonly limit: number;
}

/** A device registration. */
export interface Device {
  readonly token: string;
  readonly accountId: string;
  readonly app: App;
  readonly platform: string;
}

/** Stores the inbox and device tokens. */
export interface NotificationRepository {
  /** Stores a notification; false when its dedupe key was seen before. */
  add(n: Notification): Promise<boolean>;
  list(recipient: string, app: App, page: Page): Promise<Notification[]>;
  unread(recipient: string, app: App): Promise<number>;
  /** Marks one notification read; `notification.not_found` when it is not theirs. */
  markRead(recipient: string, app: App, id: string, at: Date): Promise<void>;
  markAllRead(recipient: string, app: App, at: Date): Promise<void>;
  /** Saves a token; it moves to whoever registered it last. */
  saveDevice(d: Device, at: Date): Promise<void>;
  /** The newest device tokens of an account in an app. */
  tokens(account: string, app: App): Promise<string[]>;
  dropToken(token: string): Promise<void>;
  /** Erases an account's inbox and devices (PRD §11). */
  forget(account: string): Promise<void>;
}

/** Injection token for the {@link NotificationRepository}. */
export const NOTIFICATION_REPOSITORY = Symbol('NotificationRepository');

/** Thrown by a {@link Pusher} when a device token will never work again. */
export class InvalidTokenError extends Error {
  constructor() {
    super('device token is no longer valid');
    this.name = 'InvalidTokenError';
  }
}

/** Delivers to one device; throws {@link InvalidTokenError} for a dead token. */
export interface Pusher {
  push(token: string, p: Push): Promise<void>;
}

/** Injection token for the {@link Pusher}. */
export const PUSHER = Symbol('Pusher');

/** A recipient's language ("bn" or "en") in an app; Bangla when unknown. */
export interface Languages {
  language(account: string, app: App): Promise<string>;
}

/** Injection token for the {@link Languages}. */
export const LANGUAGES = Symbol('Languages');

/** What notifications say about a booking. */
export interface BookingFacts {
  readonly number: string;
  readonly serviceEn: string;
  readonly serviceBn: string;
  readonly area: string;
  readonly providerName: string;
  readonly customerName: string;
}

/** Reads booking details for message text. */
export interface Bookings {
  /** The booking's details; undefined when there is no such booking. */
  booking(id: string): Promise<BookingFacts | undefined>;
}

/** Injection token for the {@link Bookings}. */
export const BOOKINGS = Symbol('Bookings');
