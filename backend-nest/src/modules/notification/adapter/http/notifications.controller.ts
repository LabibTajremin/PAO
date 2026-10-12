import { Body, Controller, Get, HttpCode, Param, Post, Put, Query } from '@nestjs/common';
import { NOT_FOUND } from '../../../../platform/http/api-error';
import { decodeCursor, encodeCursor, pageSize } from '../../../../platform/http/cursor';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components, type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { Inbox } from '../../app/inbox';
import { App, type Notification, NotificationReasons } from '../../domain/notification';

type Schemas = components['schemas'];
type PageQuery = NonNullable<operations['listCustomerNotifications']['parameters']['query']>;

const notificationErrors = { [NotificationReasons.NotFound]: NOT_FOUND };

function view(n: Notification): Schemas['Notification'] {
  return {
    id: n.id,
    type: n.type,
    title: n.title,
    body: n.body,
    ...(n.bookingId === null ? {} : { bookingId: n.bookingId }),
    read: n.read,
    createdAt: n.createdAt.toISOString(),
  };
}

/**
 * The inbox, read state and device registration, served the same way to both apps; the
 * subclasses only fix the path and the app.
 */
abstract class NotificationsController {
  constructor(
    private readonly inbox: Inbox,
    private readonly app: App,
  ) {}

  @Get('notifications')
  @RequirePermission('notification:read:own')
  async list(@CurrentPrincipal() me: Principal, @Query() q: PageQuery) {
    const cursor = decodeCursor(q.cursor);
    const size = pageSize(q.limit);
    const page = await this.inbox.page(me.accountId, this.app, {
      before: cursor && { createdAt: new Date(cursor.createdAt), id: cursor.id },
      limit: size + 1,
    });
    const items = page.items.slice(0, size);
    const last = items.at(-1);
    const more = page.items.length > size && last !== undefined;
    const out: Schemas['NotificationList'] = { items: items.map(view), unreadCount: page.unread };
    return more ? { ...out, nextCursor: encodeCursor(last) } : out;
  }

  @Post('notifications/read-all')
  @RequirePermission('notification:read:own')
  @HttpCode(204)
  async readAll(@CurrentPrincipal() me: Principal): Promise<void> {
    await this.inbox.markAllRead(me.accountId, this.app);
  }

  @Post('notifications/:notificationId/read')
  @RequirePermission('notification:read:own')
  @HttpCode(204)
  async read(@CurrentPrincipal() me: Principal, @Param('notificationId') id: string) {
    await this.inbox.markRead(me.accountId, this.app, id);
  }

  @Put('device-token')
  @RequirePermission('device:register')
  @HttpCode(204)
  async device(@CurrentPrincipal() me: Principal, @Body() body: Schemas['DeviceTokenInput']) {
    const { token, platform } = body;
    await this.inbox.registerDevice({ token, accountId: me.accountId, app: this.app, platform });
  }
}

/** The customer app's inbox (C-13). */
@Controller('v1/customer')
@MapErrors(notificationErrors)
export class CustomerNotificationsController extends NotificationsController {
  constructor(inbox: Inbox) {
    super(inbox, App.Customer);
  }
}

/** The partner app's inbox (P-12). */
@Controller('v1/provider')
@MapErrors(notificationErrors)
export class ProviderNotificationsController extends NotificationsController {
  constructor(inbox: Inbox) {
    super(inbox, App.Partner);
  }
}
