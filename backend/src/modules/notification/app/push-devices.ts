import { Inject, Injectable } from '@nestjs/common';
import { LOGGER, type Logger } from '../../../platform/logging/logger';
import { type App, type Push } from '../domain/notification';
import {
  InvalidTokenError,
  NOTIFICATION_REPOSITORY,
  type NotificationRepository,
  PUSHER,
  type Pusher,
} from '../port/ports';

/** Pushes to every device of a recipient and forgets devices that are gone. */
@Injectable()
export class PushDevices {
  constructor(
    @Inject(NOTIFICATION_REPOSITORY) private readonly repo: NotificationRepository,
    @Inject(PUSHER) private readonly pusher: Pusher,
    @Inject(LOGGER) private readonly log: Logger,
  ) {}

  /**
   * Push failures are logged, not thrown: the inbox entry is the record, and retrying
   * the event would not fix a device.
   */
  async push(recipient: string, app: App, p: Push): Promise<void> {
    for (const token of await this.repo.tokens(recipient, app)) {
      await this.pushOne(token, p);
    }
  }

  private async pushOne(token: string, p: Push): Promise<void> {
    try {
      await this.pusher.push(token, p);
    } catch (err) {
      if (err instanceof InvalidTokenError) {
        await this.repo.dropToken(token).catch((e: unknown) => {
          this.failed(e);
        });
        return;
      }
      this.failed(err);
    }
  }

  private failed(err: unknown): void {
    this.log.warn({ err }, 'push failed');
  }
}
