import { z } from 'zod';

const BASE64 = /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/;

/** Decodes standard, padded base64 strictly; returns undefined for anything else. */
export function decodeBase64(value: string): Buffer | undefined {
  return BASE64.test(value) ? Buffer.from(value, 'base64') : undefined;
}

// An empty variable counts as unset, as os.Getenv reports it in the Go backend.
const unsetIfEmpty = (v: unknown): unknown => (v === '' ? undefined : v);

/** A variable that must be set. */
export function required(name: string): z.ZodType<string> {
  return z.preprocess(unsetIfEmpty, z.string({ error: `${name} is required` }));
}

/** A variable with a fallback value. */
export function optional(fallback: string): z.ZodType<string> {
  return z.preprocess(unsetIfEmpty, z.string().default(fallback));
}

/** A variable restricted to `allowed`, defaulting to the first value. */
export function oneOf<const T extends readonly [string, ...string[]]>(
  name: string,
  allowed: T,
): z.ZodType<T[number]> {
  return z.preprocess(
    unsetIfEmpty,
    z.enum(allowed, { error: `${name} must be one of ${allowed.join(', ')}` }).default(allowed[0]),
  );
}

/** LOG_LEVEL; case-insensitive like Go's slog level names. */
export function logLevel(name: string): z.ZodType<'debug' | 'info' | 'warn' | 'error'> {
  return z.preprocess(
    (v) => (typeof v === 'string' && v !== '' ? v.toLowerCase() : undefined),
    z
      .enum(['debug', 'info', 'warn', 'error'], {
        error: `${name} must be debug, info, warn or error`,
      })
      .default('info'),
  );
}

/** A required base64 secret of exactly `size` bytes. */
export function key(name: string, size: number): z.ZodType<Buffer> {
  return required(name).transform((raw, ctx) => {
    const bytes = decodeBase64(raw);
    if (bytes?.length !== size) {
      ctx.addIssue({ code: 'custom', message: `${name} must be ${size} bytes, base64-encoded` });
      return z.NEVER;
    }
    return bytes;
  });
}
