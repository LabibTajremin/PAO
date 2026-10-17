import { appendFileSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { send, sleep, type Session } from './client';
import { obj, str } from './json';
import { e2eDir, readEnv, stack } from './stack';
import { totp, untilNextStep } from './totp';

/**
 * Keeps the admins' authenticator secrets across runs against one stack: TOTP enrolment
 * happens only on an admin's first sign-in. stack.sh removes it.
 */
const secretsFile = join(e2eDir, '.admins.env');

// Jest loads every spec file afresh, so the sessions of this run are shared through a
// file named after the process `jest --runInBand` runs them all in.
export const tokensFile = join(tmpdir(), `pao-e2e-admin-tokens-${process.pid}.json`);

function readTokens(): Record<string, string> {
  try {
    return JSON.parse(readFileSync(tokensFile, 'utf8')) as Record<string, string>;
  } catch {
    return {};
  }
}

function saveToken(email: string, token: string): void {
  writeFileSync(tokensFile, JSON.stringify({ ...readTokens(), [email]: token }), { mode: 0o600 });
}

async function secretAndChallenge(email: string): Promise<{ secret: string; challenge: string }> {
  const password = stack().adminPassword;
  const ch = (await send('POST', '/v1/auth/admin/login', { email, password })).expect(200);
  let secret = readEnv(secretsFile).get(email) ?? '';
  if (typeof ch.totpEnrolment === 'object' && ch.totpEnrolment !== null) {
    secret = str(obj(ch.totpEnrolment).secret);
    appendFileSync(secretsFile, `${email}=${secret}\n`, { mode: 0o600 });
  }
  return { secret, challenge: str(ch.challengeId) };
}

async function signInAdmin(email: string): Promise<string> {
  const { secret, challenge } = await secretAndChallenge(email);
  const enter = async () =>
    send('POST', '/v1/auth/admin/totp', {
      challengeId: challenge,
      code: await totp(secret, new Date()),
    });
  let r = await enter();
  if (r.status !== 200) {
    // A code is accepted once; a run right after the last one waits for the next.
    await sleep(untilNextStep(new Date()));
    r = await enter();
  }
  if (r.status !== 200) throw new Error(`admin ${email} totp: ${r.status} ${r.body}`);
  return str(r.json().accessToken);
}

let queue: Promise<unknown> = Promise.resolve();

/**
 * Signs a seeded admin in with password and authenticator code, enrolling TOTP on the
 * first sign-in, and reuses the session for the rest of the run.
 */
export function admin(email: string): Promise<Session> {
  const next = queue.then(async () => {
    const known = readTokens()[email];
    if (known !== undefined) return { token: known };
    const token = await signInAdmin(email);
    saveToken(email, token);
    return { token };
  });
  queue = next.catch(() => undefined);
  return next;
}
