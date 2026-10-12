import { type IncomingMessage, type ServerResponse } from 'node:http';
import { type InternalHandler, requestUrl, writeJson, writeText } from '../http/internal-server';

/** What the fake SMS adapter recorded; the identity module provides it when APP_ENV=test. */
export interface SmsCapture {
  /** Returns the phone in its stored form, or undefined if it is not a valid phone. */
  normalizePhone(raw: string): string | undefined;
  /** The newest message texted to `phone`, if any. */
  last(phone: string): string | undefined;
}

/** Injection token for the {@link SmsCapture}. */
export const SMS_CAPTURE = Symbol('SmsCapture');

/** A push notification as the capture adapter recorded it. */
export interface CapturedPush {
  readonly title: string;
  readonly body: string;
  readonly data: Readonly<Record<string, string>>;
}

/** What the fake push adapter recorded; the notification module provides it unless PUSH_ADAPTER=fcm. */
export interface PushCapture {
  sentTo(deviceToken: string): readonly CapturedPush[];
}

/** Injection token for the {@link PushCapture}. */
export const PUSH_CAPTURE = Symbol('PushCapture');

/** Runs the document-expiry sweep at a chosen time; the verification module provides it. */
export interface DocumentExpiry {
  expireDocumentsAt(at: Date): Promise<void>;
}

/** Injection token for the {@link DocumentExpiry}. */
export const DOCUMENT_EXPIRY = Symbol('DocumentExpiry');

/** The seams the hooks read; each is absent until its module exists. */
export interface TestHookSeams {
  readonly sms?: SmsCapture;
  readonly push?: PushCapture;
  readonly expiry?: DocumentExpiry;
}

const RFC3339 = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/i;

function lastSms(url: URL, res: ServerResponse, sms?: SmsCapture): void {
  const phone = sms?.normalizePhone(url.searchParams.get('phone') ?? '');
  if (sms && phone === undefined) {
    writeText(res, 400, 'bad phone');
    return;
  }
  const message = phone === undefined ? undefined : sms?.last(phone);
  if (!message) {
    writeText(res, 404, '404 page not found');
    return;
  }
  writeJson(res, 200, { message });
}

async function expireDocuments(url: URL, res: ServerResponse, expiry?: DocumentExpiry) {
  const at = url.searchParams.get('at') ?? '';
  if (!RFC3339.test(at) || Number.isNaN(Date.parse(at))) {
    writeText(res, 400, 'at must be RFC 3339');
    return;
  }
  if (!expiry) {
    writeText(res, 501, 'document expiry is not wired');
    return;
  }
  try {
    await expiry.expireDocumentsAt(new Date(at));
  } catch (err) {
    writeText(res, 500, err instanceof Error ? err.message : String(err));
    return;
  }
  res.writeHead(204).end();
}

/**
 * The `/__test/` endpoints end-to-end journeys use to read the one-time codes and pushes
 * the fake adapters captured and to run the expiry sweep on demand. Composition roots
 * mount them only when APP_ENV=test, so they never exist in production.
 */
export function testHooks(seams: TestHookSeams): InternalHandler {
  return async (req: IncomingMessage, res: ServerResponse) => {
    const url = requestUrl(req);
    const route = `${req.method ?? ''} ${url.pathname}`;
    if (route === 'GET /__test/sms') {
      lastSms(url, res, seams.sms);
    } else if (route === 'GET /__test/pushes') {
      const pushes = seams.push?.sentTo(url.searchParams.get('token') ?? '') ?? [];
      writeJson(res, 200, { pushes });
    } else if (route === 'POST /__test/verification/expire') {
      await expireDocuments(url, res, seams.expiry);
    } else {
      return false;
    }
    return true;
  };
}
