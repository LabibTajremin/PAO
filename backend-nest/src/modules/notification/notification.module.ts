import { Global, Module } from '@nestjs/common';
import {
  CustomerNotificationsController,
  ProviderNotificationsController,
} from './adapter/http/notifications.controller';
import { NotificationContract } from './adapter/inproc/notification-contract';
import { NotificationWorker } from './adapter/inproc/worker-hooks';
import { BookingDetails, ProfileLanguages } from './adapter/peers/peers';
import { PostgresNotificationRepository } from './adapter/postgres/notification-repository';
import { pushProviders } from './adapter/push/pushers';
import { EventNotes } from './app/event-notes';
import { Inbox } from './app/inbox';
import { PushDevices } from './app/push-devices';
import { SendNotification } from './app/send';
import { NOTIFICATION_SERVICE } from './contract/notification-service';
import { BOOKINGS, LANGUAGES, NOTIFICATION_REPOSITORY } from './port/ports';

/** Inbox and push delivery in Bangla and English (C-13, P-12). */
@Global()
@Module({
  controllers: [CustomerNotificationsController, ProviderNotificationsController],
  providers: [
    { provide: NOTIFICATION_REPOSITORY, useClass: PostgresNotificationRepository },
    { provide: LANGUAGES, useClass: ProfileLanguages },
    { provide: BOOKINGS, useClass: BookingDetails },
    ...pushProviders,
    PushDevices,
    SendNotification,
    Inbox,
    EventNotes,
    NotificationWorker,
    { provide: NOTIFICATION_SERVICE, useClass: NotificationContract },
  ],
  exports: [NOTIFICATION_SERVICE],
})
export class NotificationModule {}
