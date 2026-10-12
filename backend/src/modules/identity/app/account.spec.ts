import { randomUUID } from 'node:crypto';
import { DomainError } from '../../../platform/errors/domain-error';
import { boom } from '../../../../test/fakes/identity';
import { E164, harness, PHONE } from '../../../../test/fakes/identity-harness';
import { IdentityEvents } from '../contract';
import { IdentityReasons } from '../domain/reasons';

const outcome = (p: Promise<unknown>) =>
  p.then(
    () => 'resolved',
    (e: unknown) => (e instanceof DomainError ? e.reason : e),
  );

describe('my account', () => {
  it('limits a provider below Level 1 to the gate screens', async () => {
    const h = harness();
    const s = await h.login('customer');
    expect((await h.me.get(s.account.id)).id).toBe(s.account.id);
    let v = await h.me.permissions(s.account.id);
    expect(v).toMatchObject({ providerGate: false, screens: ['C01', 'C07'] });
    h.nextWindow();
    await h.login('partner');
    v = await h.me.permissions(s.account.id);
    expect(v).toMatchObject({ providerGate: true, screens: ['C01', 'C07', 'M01', 'M14'] });
    h.levels.level = 1;
    v = await h.me.permissions(s.account.id);
    expect(v.providerGate).toBe(false);
    expect(v.screens).toContain('M15');
  });

  it.each([
    ['account', 'repo', 'accountById'],
    ['grants', 'rbac', 'grants'],
    ['level', 'levels', 'getLevel'],
  ] as const)('reports a failing %s', async (_name, fake, method) => {
    const h = harness();
    const s = await h.login('partner');
    h[fake].faults.set(method, boom);
    expect(await outcome(h.me.permissions(s.account.id))).toBe(boom);
  });
});

describe('account deletion', () => {
  const deletionCode = async (h: ReturnType<typeof harness>) => {
    h.nextWindow();
    await h.phoneCodes.send({ phone: PHONE, purpose: 'delete_account' });
    return h.sentCode();
  };

  it('erases the account, ends its sessions and tells the other modules', async () => {
    const h = harness();
    const s = await h.login('customer');
    const caller = h.callerOf(s);
    await h.deletion.delete(caller, await deletionCode(h));
    const a = h.repo.accounts.get(s.account.id)!;
    expect(a).toMatchObject({ phone: '', roles: [] });
    expect(a.deletedAt).not.toBeNull();
    expect(h.families.families.size).toBe(0);
    expect(h.repo.events.at(-1)?.name).toBe(IdentityEvents.AccountDeleted);
    expect(await outcome(h.deletion.delete(caller, '123456'))).toBe(IdentityReasons.AccountDeleted);
    const stranger = { ...caller, accountId: randomUUID() };
    expect(await outcome(h.deletion.delete(stranger, '1'))).toBe(IdentityReasons.AccountNotFound);
  });

  it.each(['setRoles', 'anonymiseAccount', 'code'])('fails when %s fails', async (step) => {
    const h = harness();
    const s = await h.login('customer');
    const code = step === 'code' ? 'x' : await deletionCode(h);
    h.repo.faults.set(step, boom);
    expect(await outcome(h.deletion.delete(h.callerOf(s), code))).not.toBe('resolved');
  });
});

describe('account status', () => {
  const set = (h: ReturnType<typeof harness>, accountId: string, status: string) =>
    h.status.set({
      accountId,
      status: status as 'active',
      reason: 'fraud',
      actorId: '0199c4f0-0000-7000-8000-000000000009',
    });

  it('bans, reinstates and suspends', async () => {
    const h = harness();
    const s = await h.login('customer');
    const banned = await set(h, s.account.id, 'banned');
    expect(banned.status).toBe('banned');
    expect(h.repo.blocked.has(E164)).toBe(true);
    expect(h.families.families.size).toBe(0);
    expect(h.repo.events.at(-1)).toMatchObject({
      name: IdentityEvents.AccountStatusChanged,
      from: 'active',
      to: 'banned',
      actorId: '0199c4f0-0000-7000-8000-000000000009',
      roles: ['customer'],
    });
    await set(h, s.account.id, 'active');
    expect(h.repo.blocked.has(E164)).toBe(false);
    expect(await outcome(set(h, s.account.id, 'active'))).toBe(IdentityReasons.StatusChange);
    expect((await set(h, s.account.id, 'suspended')).status).toBe('suspended');
  });

  it('bans an admin, who has no phone', async () => {
    const h = harness();
    const { admin } = await h.newAdmin();
    await expect(set(h, admin.id, 'banned')).resolves.toMatchObject({ status: 'banned' });
  });

  it.each([
    ['accountById', 'banned'],
    ['updateStatus', 'banned'],
    ['blockPhone', 'banned'],
    ['publish', 'banned'],
    ['listForAccount', 'banned'],
    ['unblockPhone', 'active'],
  ])('fails when %s fails', async (step, to) => {
    const h = harness();
    const s = await h.login('customer');
    if (to === 'active') {
      await set(h, s.account.id, 'banned');
    }
    h.repo.faults.set(step, boom);
    h.families.faults.set(step, boom);
    expect(await outcome(set(h, s.account.id, to))).toBe(boom);
  });
});

describe('role editor', () => {
  it('lists roles and replaces grants, bumping the RBAC version', async () => {
    const h = harness();
    const c = await h.roles.list();
    expect([c.roles.length, c.allPermissions.length, c.allScreens.length]).toEqual([3, 3, 7]);
    const def = {
      role: 'verifier',
      permissions: ['verification:review', 'job:respond'],
      screens: ['A05'],
    };
    await h.roles.update(def);
    expect(h.rbac.version_).toBe(1);
    expect(h.repo.grants.get('verifier')?.permissions).toHaveLength(2);
    for (const bad of [
      { role: 'nobody', permissions: [], screens: [] },
      { role: 'verifier', permissions: ['made:up'], screens: [] },
      { role: 'verifier', permissions: [], screens: ['Z99'] },
    ]) {
      expect(await outcome(h.roles.update(bad))).toBe(IdentityReasons.RoleInvalid);
    }
  });

  it.each(['listRoles', 'loadGrants', 'catalogue'])('fails to list when %s fails', async (s) => {
    const h = harness();
    h.repo.faults.set(s, boom);
    expect(await outcome(h.roles.list())).toBe(boom);
  });

  it.each(['listRoles', 'catalogue', 'replaceRole', 'bumpVersion'])(
    'fails to update when %s fails',
    async (step) => {
      const h = harness();
      h.repo.faults.set(step, boom);
      h.rbac.faults.set(step, boom);
      const def = { role: 'verifier', permissions: [], screens: [] };
      expect(await outcome(h.roles.update(def))).toBe(boom);
    },
  );
});
