// Sign-in helpers for specs: real phone and admin
// sign-ins through the API, reading one-time codes from the SMS capture.
import { randomUUID } from 'node:crypto';
import { totpCode } from '../../src/platform/auth/totp';
import { type components } from '../../src/platform/http/openapi.gen';
import { SMS_CAPTURE, type SmsCapture } from '../../src/platform/testing/test-hooks';
import { AdminUsers } from '../../src/modules/identity/app/admin-users';
import { IDENTITY_SERVICE, type IdentityService } from '../../src/modules/identity/contract';
import { type TestApi } from './api';

/** The token pair a sign-in returns. */
export type TokenPair = components['schemas']['TokenPair'];

const RESEND_AFTER_MS = 60_000;

/** The newest one-time code texted to `phone`. */
export function lastCode(api: TestApi, phone: string): string {
  const sms = api.app.get<SmsCapture>(SMS_CAPTURE, { strict: false });
  const normalized = sms.normalizePhone(phone) ?? phone;
  const code = /[0-9]{6}/.exec(sms.last(normalized) ?? '')?.[0];
  if (code === undefined) {
    throw new Error(`no code sent to ${phone}`);
  }
  return code;
}

/** Signs in with phone + one-time code through `app` (`customer` or `partner`). */
export async function signIn(api: TestApi, phone: string, app: string): Promise<TokenPair> {
  const sent = await api.do('POST', '/v1/auth/otp/request', { phone });
  if (sent.status !== 202) {
    throw new Error(`otp request: ${sent.status} ${sent.text}`);
  }
  const code = lastCode(api, phone);
  const r = await api.do('POST', '/v1/auth/otp/verify', { phone, code, app });
  if (r.status !== 200) {
    throw new Error(`otp verify: ${r.status} ${r.text}`);
  }
  return r.body as TokenPair;
}

/** Waits out the resend timer, then signs in again. */
export function signInAgain(api: TestApi, phone: string, app: string): Promise<TokenPair> {
  api.clock.advance(RESEND_AFTER_MS);
  return signIn(api, phone, app);
}

/** Signs an access token for an existing account with the roles it holds now. */
export async function accountToken(api: TestApi, accountId: string): Promise<string> {
  const account = await api.app.get<IdentityService>(IDENTITY_SERVICE).getAccount(accountId);
  return api.token(accountId, [...account.roles]);
}

/** A signed-in admin. */
export interface AdminSession {
  readonly id: string;
  readonly email: string;
  readonly password: string;
  readonly totpSecret: string;
  readonly accessToken: string;
  /** `pao_refresh=…`, ready for a Cookie header. */
  readonly refreshCookie: string;
}

/** Creates an admin with `roles` and signs them in through password + TOTP. */
export async function adminSession(api: TestApi, roles: string[]): Promise<AdminSession> {
  const email = `${randomUUID().replaceAll('-', '').slice(0, 12)}@pao.bd`;
  const created = await api.app
    .get(AdminUsers, { strict: false })
    .create({ email, name: 'Test Admin', roles });
  const password = created.temporaryPassword;
  const login = await api.do('POST', '/v1/auth/admin/login', { email, password });
  if (login.status !== 200) {
    throw new Error(`admin login: ${login.status} ${login.text}`);
  }
  const challenge = login.body as components['schemas']['AdminLoginChallenge'];
  const totpSecret = challenge.totpEnrolment?.secret ?? '';
  const code = await totpCode(totpSecret, api.clock.now());
  const r = await api.do('POST', '/v1/auth/admin/totp', {
    challengeId: challenge.challengeId,
    code,
  });
  if (r.status !== 200) {
    throw new Error(`admin totp: ${r.status} ${r.text}`);
  }
  return {
    id: created.admin.id,
    email,
    password,
    totpSecret,
    accessToken: (r.body as TokenPair).accessToken,
    refreshCookie: (r.headers.get('set-cookie') ?? '').split(';')[0] ?? '',
  };
}
