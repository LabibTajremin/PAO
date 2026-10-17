import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { type App, type Notification } from '../domain/notification';
import {
  type Device,
  NOTIFICATION_REPOSITORY,
  type NotificationRepository,
  type Page,
} from '../port/ports';

/** A page of notifications with the unread count. */
export interface InboxPage {
  readonly items: Notification[];
  readonly unread: number;
}

/** The in-app inbox, read state and device registration of both apps. */
@Injectable()
export class Inbox {
  constructor(
    @Inject(NOTIFICATION_REPOSITORY) private readonly repo: NotificationRepository,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** A recipient's notifications in one app, newest first. */
  async page(recipient: string, app: App, page: Page): Promise<InboxPage> {
    const items = await this.repo.list(recipient, app, page);
    return { items, unread: await this.repo.unread(recipient, app) };
  }

  markRead(recipient: string, app: App, id: string): Promise<void> {
    return this.repo.markRead(recipient, app, id, this.clock.now());
  }

  markAllRead(recipient: string, app: App): Promise<void> {
    return this.repo.markAllRead(recipient, app, this.clock.now());
  }

  registerDevice(d: Device): Promise<void> {
    return this.repo.saveDevice(d, this.clock.now());
  }

  /** Erases an account's notifications and devices. */
  forget(account: string): Promise<void> {
    return this.repo.forget(account);
  }
}
