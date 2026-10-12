import { obj, type Json } from './json';
import { stack } from './stack';

/**
 * A caller; without a token it is anonymous. `ip` is the address the caller appears to
 * connect from: the API trusts X-Forwarded-For from the private network the runner
 * reaches it through, and every actor gets its own address so the per-IP limits treat
 * them as the separate devices they stand for.
 */
export interface Session {
  readonly id?: string;
  readonly token?: string;
  readonly ip?: string;
}

/** An anonymous caller with no device address of its own. */
export const anonymous: Session = {};

/** A decoded API reply. */
export class Reply {
  constructor(
    readonly status: number,
    readonly body: string,
    private readonly what = '',
  ) {}

  /** Fails unless the status is `want`; returns the body, or {} when it is empty. */
  expect(want: number): Json {
    if (this.status !== want) {
      throw new Error(`${this.what}: want ${want}, got ${this.status} ${this.body}`);
    }
    return this.body === '' ? {} : this.json();
  }

  /** The body as an object. */
  json(): Json {
    return obj(JSON.parse(this.body));
  }

  /** The error code of a failed call, or '' when there is none. */
  code(): string {
    const error = this.body === '' ? undefined : this.json().error;
    const code = typeof error === 'object' && error !== null ? (error as Json).code : undefined;
    return typeof code === 'string' ? code : '';
  }
}

/** Extra request headers by name. */
export type Headers = Record<string, string>;

const timeoutMs = 30_000;

function headersFor(s: Session, extra: Headers): Headers {
  const headers: Headers = { 'Content-Type': 'application/json' };
  if (s.token) headers.Authorization = `Bearer ${s.token}`;
  if (s.ip) headers['X-Forwarded-For'] = s.ip;
  return { ...headers, ...extra };
}

/** One HTTP request to the stack. */
export interface Request {
  readonly method: string;
  readonly path: string;
  readonly body?: unknown;
  readonly as?: Session;
  readonly headers?: Headers;
}

/** Sends a JSON request to base + path; the timeout bounds every call. */
export async function call(base: string, req: Request): Promise<Reply> {
  const res = await fetch(base + req.path, {
    method: req.method,
    headers: headersFor(req.as ?? anonymous, req.headers ?? {}),
    body: req.body === undefined ? undefined : JSON.stringify(req.body),
    signal: AbortSignal.timeout(timeoutMs),
  });
  return new Reply(res.status, await res.text(), `${req.method} ${req.path}`);
}

/** Calls the API. */
export function send(
  method: string,
  path: string,
  body: unknown,
  as: Session = anonymous,
): Promise<Reply> {
  return call(stack().api, { method, path, body, as });
}

/** GETs from the API. */
export function get(path: string, as: Session = anonymous): Promise<Reply> {
  return send('GET', path, undefined, as);
}

/**
 * Retries `check` until it passes or `withinMs` runs out; the worker relays events
 * asynchronously, so the effects of an action land shortly after it.
 */
export async function eventually(
  withinMs: number,
  what: string,
  check: () => Promise<boolean>,
): Promise<void> {
  const deadline = Date.now() + withinMs;
  while (!(await check())) {
    if (Date.now() > deadline) throw new Error(`timed out waiting for ${what}`);
    await sleep(200);
  }
}

/** Waits `ms` milliseconds. */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
