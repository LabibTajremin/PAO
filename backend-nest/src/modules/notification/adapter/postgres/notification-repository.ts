import { Inject, Injectable } from '@nestjs/common';
import { NIL as NIL_UUID } from 'uuid';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type App, type Notification, NotificationReasons } from '../../domain/notification';
import { type Device, type NotificationRepository, type Page } from '../../port/ports';
import {
  countUnread,
  deleteAccountNotifications,
  deleteAccountTokens,
  deleteToken,
  insertNotificationQuery,
  listNotifications,
  markAllRead,
  markReadQuery,
  tokensFor,
  upsertToken,
} from './sqlc/queries_sql';

/** The notification schema. */
@Injectable()
export class PostgresNotificationRepository implements NotificationRepository {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  // sqlc-gen-typescript emits only the SQL of :execrows queries, so these two run it here.
  async add(n: Notification): Promise<boolean> {
    const r = await this.db.pool.query(insertNotificationQuery, [
      n.id,
      n.recipientId,
      n.app,
      n.type,
      n.title,
      n.body,
      n.bookingId,
      n.dedupeKey,
      n.createdAt,
    ]);
    return r.rowCount === 1;
  }

  async list(recipient: string, app: App, page: Page): Promise<Notification[]> {
    const rows = await listNotifications(this.db.pool, {
      recipientId: recipient,
      app,
      beforeAt: page.before?.createdAt ?? null,
      beforeId: page.before?.id ?? NIL_UUID,
      maxRows: String(page.limit),
    });
    return rows.map(({ readAt, ...r }) => ({
      ...r,
      recipientId: recipient,
      app,
      dedupeKey: '',
      read: readAt !== null,
    }));
  }

  async unread(recipient: string, app: App): Promise<number> {
    return Number((await countUnread(this.db.pool, { recipientId: recipient, app }))?.count);
  }

  async markRead(recipient: string, app: App, id: string, at: Date): Promise<void> {
    const r = await this.db.pool.query(markReadQuery, [id, recipient, at, app]);
    if (r.rowCount === 0) {
      throw new DomainError(NotificationReasons.NotFound);
    }
  }

  markAllRead(recipient: string, app: App, at: Date): Promise<void> {
    return markAllRead(this.db.pool, { recipientId: recipient, app, readAt: at });
  }

  saveDevice(d: Device, at: Date): Promise<void> {
    return upsertToken(this.db.pool, { ...d, updatedAt: at });
  }

  async tokens(account: string, app: App): Promise<string[]> {
    return (await tokensFor(this.db.pool, { accountId: account, app })).map((r) => r.token);
  }

  dropToken(token: string): Promise<void> {
    return deleteToken(this.db.pool, { token });
  }

  async forget(account: string): Promise<void> {
    await deleteAccountNotifications(this.db.pool, { recipientId: account });
    await deleteAccountTokens(this.db.pool, { accountId: account });
  }
}
