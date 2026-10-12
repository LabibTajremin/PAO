import { type Language } from '../../../platform/i18n/text';

/** Delivery routes. SMS is reserved for OTP and critical messages (P08). */
export const Channel = {
  Push: 'push',
  Sms: 'sms',
  Inbox: 'inbox',
} as const;

/** A delivery route. */
export type Channel = (typeof Channel)[keyof typeof Channel];

/** Asks for one notification. */
export interface Message {
  readonly recipientId: string;
  /** Selects the device tokens: "customer" or "partner". */
  readonly app: string;
  readonly language: Language;
  readonly template: string;
  readonly data: Readonly<Record<string, string>>;
  readonly bookingId: string | null;
  readonly channels: readonly Channel[];
  /** Makes redelivered events notify once. */
  readonly dedupeKey: string;
}
