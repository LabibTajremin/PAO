import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { isApp, NotificationReasons } from '../domain/notification';
import { render } from '../domain/templates';
import { NOTIFICATION_REPOSITORY, type NotificationRepository } from '../port/ports';
import { PushDevices } from './push-devices';

/** Asks for one notification in one app. */
export interface Outgoing {
  readonly recipient: string;
  readonly app: string;
  readonly template: string;
  readonly data: Readonly<Record<string, string>>;
  readonly bookingId: string | null;
  /** Makes a redelivered event notify once. */
  readonly dedupeKey: string;
  /** "en" or "bn"; anything else reads as Bangla. */
  readonly language: string;
}

/** Stores a message in the inbox and pushes it to the recipient's devices (C-13, P-12). */
@Injectable()
export class SendNotification {
  constructor(
    @Inject(NOTIFICATION_REPOSITORY) private readonly repo: NotificationRepository,
    private readonly devices: PushDevices,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** A message seen before is skipped entirely, so it is neither stored nor pushed twice. */
  async send(m: Outgoing): Promise<void> {
    const { app } = m;
    const text = render(m.template, m.language, m.data);
    if (text === undefined || m.dedupeKey === '' || !isApp(app)) {
      throw new DomainError(NotificationReasons.Invalid);
    }
    const fresh = await this.repo.add({
      id: this.ids.newId(),
      recipientId: m.recipient,
      app,
      type: m.template,
      ...text,
      bookingId: m.bookingId,
      dedupeKey: m.dedupeKey,
      read: false,
      createdAt: this.clock.now(),
    });
    if (fresh) {
      const data: Record<string, string> = { type: m.template };
      if (m.bookingId !== null) {
        data.bookingId = m.bookingId;
      }
      await this.devices.push(m.recipient, app, { ...text, data });
    }
  }
}
