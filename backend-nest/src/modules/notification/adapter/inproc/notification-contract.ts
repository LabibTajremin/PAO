import { Injectable } from '@nestjs/common';
import { SendNotification } from '../../app/send';
import { type Message } from '../../contract/dto';
import { type NotificationService } from '../../contract/notification-service';

/**
 * The notification contract for other modules. Inbox and push are always used; SMS is
 * reserved for one-time codes, which identity sends itself.
 */
@Injectable()
export class NotificationContract implements NotificationService {
  constructor(private readonly sender: SendNotification) {}

  send(m: Message): Promise<void> {
    return this.sender.send({
      recipient: m.recipientId,
      app: m.app,
      template: m.template,
      data: m.data,
      bookingId: m.bookingId,
      dedupeKey: m.dedupeKey,
      language: m.language,
    });
  }
}
