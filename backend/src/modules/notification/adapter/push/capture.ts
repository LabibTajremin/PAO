import { type Logger } from '../../../../platform/logging/logger';
import { type CapturedPush, type PushCapture } from '../../../../platform/testing/test-hooks';
import { type Push } from '../../domain/notification';
import { InvalidTokenError, type Pusher } from '../../port/ports';

const KEEP = 1000;

/**
 * Logs pushes and keeps the latest ones for development and tests. Tokens starting with
 * "invalid-" are rejected as dead and "broken-" ones fail, so token clean-up and failure
 * logging can be exercised without FCM.
 */
export class CapturePusher implements Pusher, PushCapture {
  private sent: { token: string; push: CapturedPush }[] = [];

  constructor(private readonly log: Logger) {}

  push(token: string, p: Push): Promise<void> {
    if (token.startsWith('invalid-')) {
      return Promise.reject(new InvalidTokenError());
    }
    if (token.startsWith('broken-')) {
      return Promise.reject(new Error('push service unavailable'));
    }
    this.log.info({ title: p.title, type: p.data.type }, 'push');
    this.sent.push({ token, push: { title: p.title, body: p.body, data: { ...p.data } } });
    if (this.sent.length > KEEP) {
      this.sent = this.sent.slice(-KEEP);
    }
    return Promise.resolve();
  }

  /** The pushes captured for a token, oldest first. */
  sentTo(token: string): CapturedPush[] {
    return this.sent.filter((s) => s.token === token).map((s) => s.push);
  }
}
