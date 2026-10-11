// The identity use cases wired on fakes, like the Go app harness (stores_fakes_test.go).
import { totpCode } from '../../src/platform/auth/totp';
import { FakeClock } from '../../src/platform/clock/fake-clock';
import { UuidV7Generator } from '../../src/platform/ids/id-generator';
import { AccessTokens } from '../../src/modules/identity/app/access-tokens';
import { AccountStatusChanger } from '../../src/modules/identity/app/account-status';
import { AdminSignIn } from '../../src/modules/identity/app/admin-sign-in';
import { AdminTotp } from '../../src/modules/identity/app/admin-totp';
import { AdminUsers } from '../../src/modules/identity/app/admin-users';
import { AccountDeletion } from '../../src/modules/identity/app/delete-account';
import { MyAccount } from '../../src/modules/identity/app/my-account';
import { PhoneCodes } from '../../src/modules/identity/app/phone-codes';
import { PhoneAccounts, PhoneSignIn } from '../../src/modules/identity/app/phone-sign-in';
import { RoleEditor } from '../../src/modules/identity/app/role-editor';
import { type Caller, type Session, Sessions } from '../../src/modules/identity/app/sessions';
import { RESEND_AFTER_MS } from '../../src/modules/identity/domain/code';
import {
  FakeChallenges,
  FakeCodes,
  FakeDenylist,
  FakeLevels,
  FakeRbac,
  FakeRepo,
  FakeSessions,
  FakeSigner,
  FakeSms,
  FakeThrottle,
} from './identity';

export const PHONE = '01712345678';
export const E164 = '+8801712345678';

export function harness() {
  const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
  const ids = new UuidV7Generator();
  const repo = new FakeRepo(clock);
  const f = {
    clock,
    repo,
    codes: new FakeCodes(),
    throttle: new FakeThrottle(),
    families: new FakeSessions(),
    challenges: new FakeChallenges(),
    sms: new FakeSms(),
    deny: new FakeDenylist(),
    rbac: new FakeRbac(repo),
    levels: new FakeLevels(),
    signer: new FakeSigner(clock),
  };
  const phoneCodes = new PhoneCodes(repo, f.codes, f.throttle, f.sms);
  const tokens = new AccessTokens(f.signer, f.rbac, f.deny, clock);
  const sessions = new Sessions(repo, f.families, tokens, ids);
  const app = {
    phoneCodes,
    sessions,
    signIn: new PhoneSignIn(new PhoneAccounts(repo, clock, ids), phoneCodes, sessions),
    adminSignIn: new AdminSignIn(repo, f.challenges, clock, ids),
    adminTotp: new AdminTotp(repo, f.challenges, sessions, clock),
    adminUsers: new AdminUsers(repo, sessions, clock, ids),
    me: new MyAccount(repo, f.rbac, f.levels),
    deletion: new AccountDeletion(repo, phoneCodes, sessions),
    status: new AccountStatusChanger(repo, sessions),
    roles: new RoleEditor(repo, f.rbac),
  };
  return { ...f, ...app, ...sessionShortcuts(f, app) };
}

function sessionShortcuts(
  f: { sms: FakeSms; clock: FakeClock; families: FakeSessions },
  app: { phoneCodes: PhoneCodes; signIn: PhoneSignIn; adminUsers: AdminUsers },
) {
  const sentCode = (phone = E164): string => {
    const code = /[0-9]{6}/.exec(f.sms.last.get(phone) ?? '')?.[0];
    if (code === undefined) {
      throw new Error('no code sent');
    }
    return code;
  };
  return {
    sentCode,
    async login(appName: string): Promise<Session> {
      await app.phoneCodes.send({ phone: PHONE, purpose: 'login', clientIp: '1.2.3.4' });
      return app.signIn.verify({ phone: PHONE, code: sentCode(), app: appName });
    },
    nextWindow: () => {
      f.clock.advance(RESEND_AFTER_MS);
    },
    callerOf(s: Session): Caller {
      const family = [...f.families.families.values()].find((x) => x.accountId === s.account.id);
      if (!family) {
        throw new Error('no session');
      }
      return {
        accountId: s.account.id,
        sessionId: family.id,
        tokenId: family.accessTokenId,
        expiresAt: family.accessExpiresAt,
      };
    },
    async newAdmin() {
      return app.adminUsers.create({
        email: ' Verifier@PAO.bd ',
        name: 'V',
        roles: ['verifier'],
      });
    },
    totp: (secret: string) => totpCode(secret, f.clock.now()),
  };
}
