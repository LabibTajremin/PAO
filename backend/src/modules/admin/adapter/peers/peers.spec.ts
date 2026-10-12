import { type ModuleRef } from '@nestjs/core';
import { DomainError } from '../../../../platform/errors/domain-error';
import { AdminErrors } from '../../app/errors';
import { type Console } from '../../port/console';
import { LazyConsole } from './console';
import { BookingParties, IdentityAdmins, MediaEvidencePhotos } from './peers';

const boom = new Error('boom');

async function failure(p: Promise<unknown>): Promise<unknown> {
  return p.then(
    () => undefined,
    (e: unknown) => e,
  );
}

function moduleRef(byToken: Record<string, unknown>): ModuleRef {
  return { get: (token: symbol) => byToken[token.description ?? ''] } as unknown as ModuleRef;
}

describe('LazyConsole', () => {
  it('resolves each contract by its token', () => {
    const names = [
      'ProviderService',
      'CustomerService',
      'VerificationService',
      'BookingService',
      'RatingService',
      'IdentityService',
      'AuditService',
      'CatalogService',
    ];
    const c = new LazyConsole(moduleRef(Object.fromEntries(names.map((n) => [n, n]))));
    const got = [
      c.providers(),
      c.customers(),
      c.verification(),
      c.bookings(),
      c.ratings(),
      c.identity(),
      c.audit(),
      c.catalog(),
    ];
    expect(got).toEqual(names);
  });
});

describe('BookingParties', () => {
  it('maps a missing booking and passes other failures on', async () => {
    const getBooking = (id: string) =>
      id === 'b1'
        ? Promise.resolve({ customerId: 'c', providerId: 'p' })
        : Promise.reject(id === 'gone' ? new DomainError('booking.not_found') : boom);
    const parties = new BookingParties({ bookings: () => ({ getBooking }) } as unknown as Console);
    expect(await parties.parties('b1')).toEqual({ customerId: 'c', providerId: 'p' });
    const gone = await failure(parties.parties('gone'));
    expect(gone).toMatchObject({ reason: AdminErrors.BookingNotFound });
    expect(await failure(parties.parties('x'))).toBe(boom);
  });
});

describe('MediaEvidencePhotos', () => {
  const objects: Record<string, unknown> = {
    ok: { ownerId: 'me', purpose: 'complaint_photo', confirmed: true },
    other: { ownerId: 'you', purpose: 'complaint_photo', confirmed: true },
    avatar: { ownerId: 'me', purpose: 'avatar', confirmed: true },
    draft: { ownerId: 'me', purpose: 'complaint_photo', confirmed: false },
    stuck: { ownerId: 'me', purpose: 'complaint_photo', confirmed: true },
  };
  const attached: string[] = [];
  const media = {
    getObject: (id: string) =>
      id in objects
        ? Promise.resolve(objects[id])
        : Promise.reject(id === 'missing' ? new DomainError('media.not_found') : boom),
    markAttached: (id: string) =>
      id === 'stuck' ? Promise.reject(boom) : Promise.resolve(void attached.push(id)),
  };
  const photos = new MediaEvidencePhotos(moduleRef({ MediaService: media }));

  it('attaches the owner’s confirmed complaint photos', async () => {
    await photos.attach('me', ['ok']);
    expect(attached).toEqual(['ok']);
  });

  it.each(['other', 'avatar', 'draft', 'missing'])('refuses a %s photo', async (id) => {
    expect(await failure(photos.attach('me', [id]))).toMatchObject({
      reason: AdminErrors.PhotoInvalid,
    });
  });

  it('passes media failures on after trying every photo', async () => {
    expect(await failure(photos.attach('me', ['broken']))).toBe(boom);
    expect(await failure(photos.attach('me', ['stuck', 'ok']))).toBe(boom);
    expect(attached).toEqual(['ok', 'ok']);
  });
});

describe('IdentityAdmins', () => {
  const accounts: Record<string, unknown> = {
    agent: { status: 'active', roles: ['support_agent'] },
    root: { status: 'active', roles: ['super_admin'] },
    off: { status: 'suspended', roles: ['support_agent'] },
    verifier: { status: 'active', roles: ['verifier'] },
  };
  const getAccount = (id: string) =>
    id in accounts
      ? Promise.resolve(accounts[id])
      : Promise.reject(id === 'none' ? new DomainError('identity.account_not_found') : boom);
  const admins = new IdentityAdmins({ identity: () => ({ getAccount }) } as unknown as Console);

  it.each([
    ['agent', true],
    ['root', true],
    ['off', false],
    ['verifier', false],
    ['none', false],
  ])('%s may work complaints: %s', async (id, ok) => {
    expect(await admins.canWorkComplaints(id)).toBe(ok);
  });

  it('passes identity failures on', async () => {
    expect(await failure(admins.canWorkComplaints('x'))).toBe(boom);
  });
});
