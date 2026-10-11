// Text message delivery: the console for development, a capture for tests and the
// SSL Wireless gateway for production (D10).
import { type IdGenerator } from '../../../../platform/ids/id-generator';
import { type Logger } from '../../../../platform/logging/logger';
import { type SmsCapture } from '../../../../platform/testing/test-hooks';
import { normalizePhone } from '../../domain/phone';
import { type SmsSender } from '../../port/outside-world';

/** Logs messages instead of sending them; codes appear in the API log. */
export class ConsoleSms implements SmsSender {
  constructor(private readonly log: Logger) {}

  send(phone: string, message: string): Promise<void> {
    this.log.info({ phone, message }, 'sms (console adapter)');
    return Promise.resolve();
  }
}

/**
 * Keeps the newest message per phone in memory so end-to-end tests can read one-time
 * codes; wired only when APP_ENV=test.
 */
export class CapturedSms implements SmsSender, SmsCapture {
  private readonly latest = new Map<string, string>();

  send(phone: string, message: string): Promise<void> {
    this.latest.set(phone, message);
    return Promise.resolve();
  }

  normalizePhone(raw: string): string | undefined {
    return normalizePhone(raw);
  }

  last(phone: string): string | undefined {
    return this.latest.get(phone);
  }
}

/** Where and as whom the SSL Wireless SMS Plus API is called. */
export interface SslWirelessOptions {
  readonly endpoint: string;
  readonly apiToken: string;
  readonly sid: string;
  readonly timeoutMs: number;
}

/** The production SMS endpoint. */
export const SSL_WIRELESS_ENDPOINT = 'https://smsplus.sslwireless.com/api/v3/send-sms';

/** Sends through the SSL Wireless SMS Plus API. */
export class SslWirelessSms implements SmsSender {
  constructor(
    private readonly options: SslWirelessOptions,
    private readonly ids: IdGenerator,
  ) {}

  async send(phone: string, message: string): Promise<void> {
    const body = JSON.stringify({
      api_token: this.options.apiToken,
      sid: this.options.sid,
      msisdn: phone.replace(/^\+/, ''),
      sms: message,
      // The gateway's client message id is at most 20 characters.
      csms_id: this.ids.newId().replaceAll('-', '').slice(0, 20),
    });
    let res: Response;
    try {
      res = await fetch(this.options.endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body,
        signal: AbortSignal.timeout(this.options.timeoutMs),
      });
    } catch (cause) {
      throw new Error('sms gateway', { cause });
    }
    const out = (await res.json().catch(() => ({}))) as { status_code?: number };
    if (out.status_code !== 200) {
      throw new Error(
        `sms gateway rejected the message (http ${res.status}, status ${out.status_code ?? 0})`,
      );
    }
  }
}
