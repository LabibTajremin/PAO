import { generate } from 'otplib';

/** The RFC 6238 code (SHA-1, 30 s, 6 digits) an authenticator app shows at `at`. */
export function totp(secret: string, at: Date): Promise<string> {
  return generate({ secret, epoch: Math.floor(at.getTime() / 1000) });
}

/** Milliseconds until one second into the next 30-second TOTP step. */
export function untilNextStep(now: Date): number {
  const stepMs = 30_000;
  return stepMs - (now.getTime() % stepMs) + 1000;
}
