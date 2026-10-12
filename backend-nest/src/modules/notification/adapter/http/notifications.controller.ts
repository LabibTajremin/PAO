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
type List = Schemas['NotificationList'];
type PageQuery = NonNullable<operations['listCustomerNotifications']['parameters']['query']>;
type DeviceInput = Schemas['DeviceTokenInput'];

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

/** One page of an app's inbox, newest first, with the unread count. */
async function list(inbox: Inbox, me: string, app: App, q: PageQuery): Promise<List> {
  const cursor = decodeCursor(q.cursor);
  const size = pageSize(q.limit);
  const page = await inbox.page(me, app, {
    before: cursor && { createdAt: new Date(cursor.createdAt), id: cursor.id },
    limit: size + 1,
  });
  const items = page.items.slice(0, size);
  const last = items.at(-1);
  const out: List = { items: items.map(view), unreadCount: page.unread };
  return page.items.length > size && last ? { ...out, nextCursor: encodeCursor(last) } : out;
}

// The two apps are served the same way; each controller only fixes its path and app.

/** The customer app's inbox and device (C-13). */
@Controller('v1/customer')
@MapErrors(notificationErrors)
export class CustomerNotificationsController {
  constructor(private readonly inbox: Inbox) {}

  @Get('notifications')
  @RequirePermission('notification:read:own')
  list(@CurrentPrincipal() me: Principal, @Query() q: PageQuery): Promise<List> {
    return list(this.inbox, me.accountId, App.Customer, q);
  }

  @Post('notifications/read-all')
  @RequirePermission('notification:read:own')
  @HttpCode(204)
  readAll(@CurrentPrincipal() me: Principal): Promise<void> {
    return this.inbox.markAllRead(me.accountId, App.Customer);
  }

  @Post('notifications/:notificationId/read')
  @RequirePermission('notification:read:own')
  @HttpCode(204)
  read(@CurrentPrincipal() me: Principal, @Param('notificationId') id: string): Promise<void> {
    return this.inbox.markRead(me.accountId, App.Customer, id);
  }

  @Put('device-token')
  @RequirePermission('device:register')
  @HttpCode(204)
  device(@CurrentPrincipal() me: Principal, @Body() body: DeviceInput): Promise<void> {
    const { token, platform } = body;
    return this.inbox.registerDevice({
      token,
      platform,
      accountId: me.accountId,
      app: App.Customer,
    });
  }
}

/** The partner app's inbox and device (P-12). */
@Controller('v1/provider')
@MapErrors(notificationErrors)
export class ProviderNotificationsController {
  constructor(private readonly inbox: Inbox) {}

  @Get('notifications')
  @RequirePermission('notification:read:own')
  list(@CurrentPrincipal() me: Principal, @Query() q: PageQuery): Promise<List> {
    return list(this.inbox, me.accountId, App.Partner, q);
  }

  @Post('notifications/read-all')
  @RequirePermission('notification:read:own')
  @HttpCode(204)
  readAll(@CurrentPrincipal() me: Principal): Promise<void> {
    return this.inbox.markAllRead(me.accountId, App.Partner);
  }

  @Post('notifications/:notificationId/read')
  @RequirePermission('notification:read:own')
  @HttpCode(204)
  read(@CurrentPrincipal() me: Principal, @Param('notificationId') id: string): Promise<void> {
    return this.inbox.markRead(me.accountId, App.Partner, id);
  }

  @Put('device-token')
  @RequirePermission('device:register')
  @HttpCode(204)
  device(@CurrentPrincipal() me: Principal, @Body() body: DeviceInput): Promise<void> {
    const { token, platform } = body;
    return this.inbox.registerDevice({
      token,
      platform,
      accountId: me.accountId,
      app: App.Partner,
    });
  }
}
