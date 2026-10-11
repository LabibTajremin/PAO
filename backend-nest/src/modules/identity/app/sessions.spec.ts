import { randomUUID } from 'node:crypto';
import { DomainError, isDomainError } from '../../../platform/errors/domain-error';
import { boom } from '../../../../test/fakes/identity';
import { harness } from '../../../../test/fakes/identity-harness';
import { IdentityReasons } from '../domain/reasons';

const reasonOf = (p: Promise<unknown>) =>
  p.then(
    () => 'resolved',
    (e: unknown) => (e instanceof DomainError ? e.reason : e),
  );

describe('sessions', () => {
  it('rotates the refresh token and revokes the family on reuse', async () => {
    const h = harness();
    const s = await h.login('customer');
    const next = await h.sessions.refresh(s.refreshToken);
    expect(next.refreshToken).not.toBe(s.refreshToken);
    expect(next.accessToken).not.toBe('');
    expect(await reasonOf(h.sessions.refresh(s.refreshToken))).toBe(IdentityReasons.RefreshReused);
    expect(h.sessions.families.size).toBe(0);
    expect(h.deny.denied).toHaveLength(1);
    expect(await reasonOf(h.sessions.refresh(next.refreshToken))).toBe(
      IdentityReasons.RefreshInvalid,
    );
  });

  it('refuses garbage, lookup failures and suspended accounts', async () => {
    const h = harness();
    expect(await reasonOf(h.sessions.refresh('garbage'))).toBe(IdentityReasons.RefreshInvalid);
    const s = await h.login('customer');
    h.repo.faults.set('accountById', boom);
    expect(await reasonOf(h.sessions.refresh(s.refreshToken))).toBe(boom);
    h.repo.faults.clear();
    h.repo.accounts.set(s.account.id, { ...s.account, status: 'suspended' });
    expect(await reasonOf(h.sessions.refresh(s.refreshToken))).toBe(
      IdentityReasons.AccountSuspended,
    );
    expect(h.sessions.families.size).toBe(0);
  });

  it('logs out one device or all of them', async () => {
    const h = harness();
    const s = await h.login('customer');
    const caller = h.callerOf(s);
    h.nextWindow();
    await h.login('customer');
    await h.sessions.logout(caller, false);
    expect(h.sessions.families.size).toBe(1);
    await h.sessions.logout({ ...caller, sessionId: randomUUID() }, false);
    const other = [...h.sessions.families.values()][0]!;
    await h.sessions.logout({ ...caller, sessionId: other.id }, true);
    expect(h.sessions.families.size).toBe(0);
  });

  it.each([
    ['deny', 'deny', 'deny'],
    ['get', 'sessions', 'get'],
    ['list', 'sessions', 'listForAccount'],
    ['delete', 'sessions', 'delete'],
  ] as const)('reports a failing %s on logout', async (_name, fake, method) => {
    const h = harness();
    const caller = h.callerOf(await h.login('customer'));
    h[fake].faults.set(method, boom);
    const one = await reasonOf(h.sessions.logout(caller, false));
    const all = await reasonOf(h.sessions.logout(caller, true));
    expect([one, all]).toContain(boom);
  });

  it('keeps the refusal when ending a reused family fails', async () => {
    const h = harness();
    const s = await h.login('customer');
    await h.sessions.refresh(s.refreshToken);
    h.deny.faults.set('deny', boom);
    const err = await h.sessions.refresh(s.refreshToken).catch((e: unknown) => e);
    expect(isDomainError(err, IdentityReasons.RefreshReused)).toBe(true);
    expect((err as Error).cause).toBe(boom);
  });
});
