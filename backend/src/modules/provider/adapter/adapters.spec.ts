import { type ModuleRef } from '@nestjs/core';
import type Redis from 'ioredis';
import { boom, providerFixture } from '../../../../test/fakes/provider';
import { type Database } from '../../../platform/db/database';
import { DomainError } from '../../../platform/errors/domain-error';
import { type EventBus, type EventHandler } from '../../../platform/events/event-bus';
import { RedisKeys } from '../../../platform/redis/redis-client';
import { ADMIN_SERVICE } from '../../admin/contract/admin-service';
import { CATALOG_SERVICE } from '../../catalog/contract/catalog-service';
import { IDENTITY_SERVICE } from '../../identity/contract/identity-service';
import { MEDIA_SERVICE } from '../../media/contract/media-service';
import { RATING_SERVICE } from '../../rating/contract/rating-service';
import { HEARTBEAT_EVERY_S } from '../app/presence';
import { NO_CONTACT } from '../domain/provider';
import { ProviderReasons } from '../domain/reasons';
import { PublicProfileController } from './http/profile.controller';
import { ProviderContract } from './inproc/provider-contract';
import {
  AdminQuality,
  CatalogServices,
  IdentityAccounts,
  MediaAvatars,
  ProviderRatings,
} from './peers/peers';
import { type ProviderOutbox } from './postgres/outbox';
import { ReadModelHandlers } from './postgres/read-model';
import { RedisPresence } from './redis/presence';

function refTo(contracts: Map<symbol, unknown>): ModuleRef {
  return { get: (token: symbol) => contracts.get(token) } as unknown as ModuleRef;
}

describe('provider peers', () => {
  it('passes unexpected contract errors on and maps the rest', async () => {
    const rating = { average: 4, count: 1, distribution: [0, 0, 0, 1, 0] };
    const ref = refTo(
      new Map<symbol, unknown>([
        [CATALOG_SERVICE, { getService: () => Promise.reject(boom) }],
        [
          IDENTITY_SERVICE,
          {
            sendPhoneCode: () => Promise.reject(new Error('down')),
            // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors -- a peer that rejects with a non-Error must still surface as an Error
            checkPhoneCode: () => Promise.reject('odd'),
          },
        ],
        [
          MEDIA_SERVICE,
          {
            getObject: () => Promise.reject(boom),
            getViewUrl: () => Promise.resolve({ url: 'u' }),
          },
        ],
        [
          ADMIN_SERVICE,
          {
            getSettings: () =>
              Promise.resolve({
                ratingFloor: 3.5,
                ratingMinJobs: 10,
                maxProviderCancellations30d: 3,
              }),
          },
        ],
        [RATING_SERVICE, { getProviderRating: () => Promise.resolve(rating) }],
      ]),
    );
    await expect(new CatalogServices(ref).service('s')).rejects.toBe(boom);
    const accounts = new IdentityAccounts(ref);
    await expect(accounts.sendContactCode('p')).rejects.toThrow('down');
    await expect(accounts.checkContactCode('p', '1')).rejects.toThrow('odd');
    const media = new MediaAvatars(ref);
    await expect(media.attachAvatar('o', 'm')).rejects.toBe(boom);
    expect(await media.url('v', 'm')).toBe('u');
    expect(await new AdminQuality(ref).quality()).toEqual({
      ratingFloor: 3.5,
      ratingMinJobs: 10,
      maxCancellations: 3,
    });
    expect(await new ProviderRatings(ref).providerRating('p')).toBe(rating);
  });
});

describe('provider adapters', () => {
  it('fails a presence change when Redis rejects a command', async () => {
    const tx = {
      geoadd: () => tx,
      set: () => tx,
      sadd: () => tx,
      exec: () => Promise.resolve([[boom, null]]),
    };
    const redis = { multi: () => tx } as unknown as Redis;
    const presence = new RedisPresence(redis, new RedisKeys('test'));
    await expect(presence.online('p', ['s'], { lat: 0, lng: 0 })).rejects.toBe(boom);
    const empty = { ...tx, exec: () => Promise.resolve(null) };
    await new RedisPresence({ multi: () => empty } as unknown as Redis, new RedisKeys('t')).online(
      'p',
      [],
      { lat: 0, lng: 0 },
    );
  });

  it('lists providers for admins and shows public profiles', async () => {
    const f = providerFixture();
    const contract = new ProviderContract(f.profiles, f.enrolment, f.manage, f.finder);
    const q = {
      id: null,
      text: '',
      status: '',
      level: null,
      flagged: null,
      afterAt: null,
      afterId: null,
      limit: 20,
    };
    expect(await contract.searchProviders(q)).toEqual([]);
    f.repo.rows.set('p', { ...(await f.profiles.load('p')), level: 1, photoMediaId: 'ph' });
    const view = await new PublicProfileController(f.public).get({ accountId: 'v' } as never, 'p');
    expect(view).toMatchObject({
      badge: 'verified',
      photoUrl: 'https://media/ph',
      rating: { distribution: { '4': 1, '5': 1 } },
    });
    expect([HEARTBEAT_EVERY_S, NO_CONTACT.phone]).toEqual([30, '']);
  });

  it('rethrows offline failures other than an unknown provider', async () => {
    const handlers = new Map<string, EventHandler>();
    const bus = {
      subscribe: (name: string, _h: string, fn: EventHandler) => handlers.set(name, fn),
    } as unknown as EventBus;
    const tx = { query: () => Promise.resolve({ rowCount: 1, rows: [] }) };
    const db = {
      transaction: (fn: (t: typeof tx) => Promise<void>) => fn(tx),
    } as unknown as Database;
    const presence = { goOffline: () => Promise.reject(boom) };
    const outbox = {} as ProviderOutbox;
    new ReadModelHandlers(db, outbox, providerFixture().peers, presence as never).subscribe(bus);
    const env = {
      id: 'e',
      name: 'identity.AccountDeleted',
      payload: { accountId: 'a' },
      occurredAt: new Date(),
    };
    await expect(handlers.get('identity.AccountDeleted')?.(env as never)).rejects.toBe(boom);
    presence.goOffline = () => Promise.reject(new DomainError(ProviderReasons.NotFound));
    await handlers.get('identity.AccountDeleted')?.(env as never);
  });
});
