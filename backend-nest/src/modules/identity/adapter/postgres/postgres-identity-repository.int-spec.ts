import { randomBytes, randomUUID } from 'node:crypto';
import { onCleanup } from '../../../../../test/kit/cleanup';
import { migratedDatabase } from '../../../../../test/kit/postgres';
import { DataCipher } from '../../../../platform/auth/data-cipher';
import { FakeClock } from '../../../../platform/clock/fake-clock';
import { connectDatabase, type Database } from '../../../../platform/db/database';
import { UuidV7Generator } from '../../../../platform/ids/id-generator';
import { type Account } from '../../domain/account';
import { PostgresIdentityRepository } from './postgres-identity-repository';

const account = (over: Partial<Account> = {}): Account => ({
  id: randomUUID(),
  phone: '',
  email: '',
  name: '',
  status: 'active',
  roles: [],
  createdAt: new Date(),
  deletedAt: null,
  ...over,
});

describe('identity repository', () => {
  let db: Database;
  let repo: PostgresIdentityRepository;

  beforeAll(async () => {
    db = await connectDatabase(await migratedDatabase());
    onCleanup(() => db.close());
    const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
    repo = new PostgresIdentityRepository(
      db,
      clock,
      new UuidV7Generator(),
      new DataCipher(randomBytes(32)),
    );
  });

  it('reports constraint failures inside transactions', async () => {
    const a = account({ phone: '+8801712345678' });
    await repo.inTx((tx) => tx.createAccount(a));
    const failing = [
      repo.inTx((tx) => tx.setRoles(a.id, ['pilot'])),
      repo.inTx((tx) => tx.replaceRole('verifier', { permissions: ['made:up'], screens: [] })),
      repo.inTx((tx) => tx.replaceRole('verifier', { permissions: [], screens: ['Z99'] })),
    ];
    for (const p of failing) {
      await expect(p).rejects.toThrow();
    }
    expect(await repo.loadGrants('verifier')).not.toEqual({ permissions: [], screens: [] });
  });

  it('treats an account without credentials as no admin, and stores TOTP secrets encrypted', async () => {
    const a = account({ email: 'A@pao.bd' });
    await repo.inTx((tx) => tx.createAccount(a));
    await expect(repo.adminByEmail(' a@PAO.bd ')).rejects.toThrow('account_not_found');
    await repo.inTx((tx) => tx.createAdminCredentials(a.id, 'h'));
    const admin = await repo.adminByEmail('a@pao.bd');
    expect(admin).toMatchObject({ email: 'a@pao.bd', totpSecret: '', mustChangePassword: true });
    await repo.inTx((tx) => tx.saveAdmin({ ...admin, totpSecret: 'JBSWY3DPEHPK3PXP' }));
    expect((await repo.adminById(a.id)).totpSecret).toBe('JBSWY3DPEHPK3PXP');
    const raw = await db.query<{ totp_secret_enc: Buffer }>(
      'SELECT totp_secret_enc FROM identity.admin_credentials WHERE account_id = $1',
      [a.id],
    );
    expect(raw.rows[0]?.totp_secret_enc.toString()).not.toContain('JBSWY3DPEHPK3PXP');
    expect((await repo.listAdmins()).map((x) => x.id)).toEqual([a.id]);
    expect(await repo.isPhoneBlocked('+8801999999999')).toBe(false);
  });
});
