import { Inject, Injectable } from '@nestjs/common';
import { type Envelope } from '../../../platform/events/event-bus';
import { Payload } from '../../../platform/events/payload';
import { LOGGER, type Logger } from '../../../platform/logging/logger';
import { AdminEvents } from '../../admin/contract/events';
import { VerificationEvents } from '../../verification/contract/events';
import { App } from '../domain/notification';
import { BOOKINGS, type Bookings, LANGUAGES, type Languages } from '../port/ports';
import { BOOKING_NOTES, type Note } from './booking-notes';
import { SendNotification } from './send';

/** Handles one delivered event. */
export type Handler = (env: Envelope) => Promise<void>;

/** Verification items in English and Bangla, for message text. */
const ITEMS: Readonly<Record<string, readonly [string, string]>> = {
  nid: ['NID', 'এনআইডি'],
  selfie: ['selfie', 'সেলফি'],
  police_clearance: ['police clearance', 'পুলিশ ক্লিয়ারেন্স'],
  address: ['address', 'ঠিকানা'],
  emergency_contact: ['emergency contact', 'জরুরি যোগাযোগ'],
  skill_proof: ['skill proof', 'দক্ষতার প্রমাণ'],
  service_area: ['service area', 'সেবা এলাকা'],
  code_of_conduct: ['code of conduct', 'আচরণবিধি'],
};

function itemName(item: string, language: string): string {
  const names = Object.hasOwn(ITEMS, item) ? ITEMS[item] : undefined;
  return (language === 'en' ? names?.[0] : names?.[1]) ?? '';
}

type ProviderText = (p: Payload, language: string) => Record<string, string>;

/** What each verification event tells the provider. */
const VERIFICATION_NOTES: Readonly<Record<string, [template: string, data: ProviderText]>> = {
  [VerificationEvents.ProviderLevelChanged]: [
    'level_changed',
    (p) => ({ level: String(p.number('to')) }),
  ],
  [VerificationEvents.DocumentRejected]: [
    'document_rejected',
    (p, l) => ({ item: itemName(p.text('item'), l), reason: p.text('reason') }),
  ],
  [VerificationEvents.DocumentExpired]: [
    'document_expired',
    (p, l) => ({ item: itemName(p.text('item'), l) }),
  ],
  [VerificationEvents.DocumentExpiring]: [
    'document_expiring',
    (p, l) => ({ item: itemName(p.text('item'), l), days: String(p.number('daysLeft')) }),
  ],
  [VerificationEvents.Level2SessionScheduled]: [
    'level2_scheduled',
    (p) => ({ location: p.text('location'), when: p.text('scheduledAt') }),
  ],
};

/** Turns other modules' events into notifications; dedupe keys make redelivery harmless. */
@Injectable()
export class EventNotes {
  constructor(
    private readonly sender: SendNotification,
    @Inject(LANGUAGES) private readonly languages: Languages,
    @Inject(BOOKINGS) private readonly bookings: Bookings,
    @Inject(LOGGER) private readonly log: Logger,
  ) {}

  /** Every event that notifies someone, by name. */
  handlers(): Record<string, Handler> {
    const out: Record<string, Handler> = {
      [AdminEvents.ComplaintResolved]: (env) => this.complaintResolved(env),
    };
    for (const [name, [template, data]] of Object.entries(VERIFICATION_NOTES)) {
      out[name] = (env) => this.toProvider(env, template, data);
    }
    for (const [name, notes] of Object.entries(BOOKING_NOTES)) {
      out[name] = (env) => this.onBooking(env, notes);
    }
    return out;
  }

  private async toProvider(env: Envelope, template: string, data: ProviderText): Promise<void> {
    const p = new Payload(env);
    const recipient = p.id('providerId');
    const language = await this.languages.language(recipient, App.Partner);
    await this.sender.send({
      recipient,
      app: App.Partner,
      template,
      data: data(p, language),
      bookingId: null,
      dedupeKey: env.id,
      language,
    });
  }

  private async complaintResolved(env: Envelope): Promise<void> {
    const p = new Payload(env);
    const recipient = p.id('reporterId');
    const app = { customer: App.Customer, provider: App.Partner }[p.text('reporterRole')] ?? '';
    await this.sender.send({
      recipient,
      app,
      template: 'complaint_resolved',
      data: { ticket: p.text('ticketNumber') },
      bookingId: null,
      dedupeKey: env.id,
      language: app === '' ? 'bn' : await this.languages.language(recipient, app),
    });
  }

  private async onBooking(env: Envelope, notes: (p: Payload) => Note[]): Promise<void> {
    const p = new Payload(env);
    const list = notes(p);
    const bookingId = p.id('bookingId');
    const b = await this.bookings.booking(bookingId);
    if (b === undefined) {
      // Retrying cannot make a missing booking appear, so the event is dropped rather
      // than blocking the outbox.
      this.log.warn({ booking: bookingId, event: env.name }, 'notification for unknown booking');
      return;
    }
    for (const n of list) {
      const language = await this.languages.language(n.to, n.app);
      const service = language === 'en' ? b.serviceEn : b.serviceBn;
      const data = {
        number: b.number,
        service,
        area: b.area,
        provider: b.providerName,
        customer: b.customerName,
        ...n.extra,
      };
      await this.sender.send({
        recipient: n.to,
        app: n.app,
        template: n.template,
        data,
        bookingId,
        dedupeKey: `${env.id}:${n.template}`,
        language,
      });
    }
  }
}
