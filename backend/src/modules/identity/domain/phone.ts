const BD_MOBILE = /^(?:\+?880|0)?(1[3-9][0-9]{8})$/;

/**
 * Accepts the common ways people type a Bangladeshi mobile number (01712…, 8801712…,
 * +880 1712-…) and returns its E.164 form, or undefined when it is not one.
 */
export function normalizePhone(raw: string): string | undefined {
  const match = BD_MOBILE.exec(raw.trim().replace(/[ ()-]/g, ''));
  return match?.[1] === undefined ? undefined : `+880${match[1]}`;
}

/** Hides all but the last three digits, for logs and messages. */
export function maskPhone(phone: string): string {
  return phone.length < 3 ? '***' : '*'.repeat(phone.length - 3) + phone.slice(-3);
}
