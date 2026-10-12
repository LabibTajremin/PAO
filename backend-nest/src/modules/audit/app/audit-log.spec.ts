import { randomUUID } from 'node:crypto';
import { FakeClock } from '../../../platform/clock/fake-clock';
import { isDomainError } from '../../../platform/errors/domain-error';
import { EventBus } from '../../../platform/events/event-bus';
import { UuidV7Generator } from '../../../platform/ids/id-generator';
import { AuditSubscribers } from '../adapter/worker/audit-subscribers';
import { AuditReasons, type Entry, isComplete } from '../domain/entry';
import { type EntryRepository } from '../port/entry-repository';
import { AuditLog } from './audit-log';
import { EVENT_ENTRIES } from './event-entries';

class MemoryEntries implements EntryRepository {
  readonly entries: Entry[] = [];
  append(e: Entry) {
    this.entries.push(e);
    return Promise.resolve();
  }
  list() {
    return Promise.resolve(this.entries);
  }
}

const now = new Date('2026-10-09T10:00:00Z');
const base = { actorId: null, actorRole: '', reason: '', before: null, after: null };

describe('audit entries', () => {
  it('need an action and a subject', () => {
    expect(isComplete({ action: 'a', subjectType: 'provider', subjectId: '1' })).toBe(true);
    expect(isComplete({ action: ' ', subjectType: 'provider', subjectId: '1' })).toBe(false);
  });
});

describe('audit log', () => {
  it('fills in id and time and refuses incomplete entries', async () => {
    const repo = new MemoryEntries();
    const log = new AuditLog(repo, new FakeClock(now), new UuidV7Generator());
    await log.record({ ...base, action: 'x', subjectType: 'y', subjectId: 'z' });
    expect(repo.entries[0]).toMatchObject({ at: now, eventId: null });
    expect(repo.entries[0]?.id).toHaveLength(36);
    const err = await log
      .record({ ...base, action: '', subjectType: '', subjectId: '' })
      .catch((e: unknown) => e);
    expect(isDomainError(err, AuditReasons.Invalid)).toBe(true);
    expect(await log.list({}, { limit: 10 })).toHaveLength(1);
  });

  it('audits every subscribed event once per delivery and rejects broken payloads', async () => {
    const repo = new MemoryEntries();
    const bus = new EventBus();
    new AuditSubscribers(new AuditLog(repo, new FakeClock(now), new UuidV7Generator())).subscribe(
      bus,
    );
    const actor = randomUUID();
    const payloads: Record<string, object> = {
      'identity.AccountStatusChanged': {
        accountId: randomUUID(),
        from: 'active',
        to: 'banned',
        reason: 'x',
        actorId: actor,
      },
      'catalog.PriceChanged': {
        subServiceId: randomUUID(),
        priceVersionId: randomUUID(),
        amountPaisa: 100,
        actorId: null,
      },
      'verification.DocumentApproved': { providerId: randomUUID(), item: 'nid', actorId: actor },
      'verification.DocumentRejected': {
        providerId: randomUUID(),
        item: 'nid',
        reason: 'blurred',
        actorId: actor,
      },
      'verification.ProviderLevelChanged': { providerId: randomUUID(), from: 0, to: 1, reason: '' },
      'verification.Level2ResultRecorded': {
        providerId: randomUUID(),
        sessionId: randomUUID(),
        result: 'pass',
        actorId: actor,
      },
      'verification.DocumentExpired': { providerId: randomUUID(), item: 'police_clearance' },
      'admin.SettingChanged': {
        key: 'search.default_radius_m',
        before: '5000',
        after: '6000',
        actorId: actor,
      },
      'admin.ComplaintResolved': {
        complaintId: randomUUID(),
        ticketNumber: 'TCK-000001',
        verified: true,
        againstId: randomUUID(),
        actorId: actor,
      },
    };
    expect(Object.keys(EVENT_ENTRIES).sort()).toEqual(Object.keys(payloads).sort());
    for (const [name, payload] of Object.entries(payloads)) {
      const env = { id: randomUUID(), module: 'm', name, aggregateId: '', occurredAt: now };
      await bus.dispatch({ ...env, payload: { name, ...payload } });
      await expect(bus.dispatch({ ...env, payload: { name } })).rejects.toThrow();
    }
    expect(repo.entries).toHaveLength(9);
    expect(repo.entries[0]).toMatchObject({
      action: 'account.status_changed',
      actorId: actor,
      before: { status: 'active' },
      after: { status: 'banned' },
    });
    expect(repo.entries.every((e) => e.eventId !== null && e.at === now)).toBe(true);
  });
});
