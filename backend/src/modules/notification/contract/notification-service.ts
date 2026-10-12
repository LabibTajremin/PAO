import { type Message } from './dto';

/** What other modules may ask of the notification module (PRD §9.3 rule 1). */
export interface NotificationService {
  /**
   * Renders a template in the recipient's language and delivers it on the requested
   * channels. Delivery is idempotent per (recipient, template, dedupe key).
   */
  send(message: Message): Promise<void>;
}

/** Injection token for the {@link NotificationService}. */
export const NOTIFICATION_SERVICE = Symbol('NotificationService');
