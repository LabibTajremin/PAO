import { Inject, Injectable } from '@nestjs/common';
import { retryAfter, type Session } from '../domain/level2';
import { canReceiveBookings, type State } from '../domain/state';
import { PROVIDERS, type Providers, SETTINGS, type Settings } from '../port/peers';
import { States } from './states';

/** The provider's verification screen (M14/P-03). */
export interface Status extends State {
  readonly canReceiveBookings: boolean;
  readonly level2Eligible: boolean;
  readonly retryAfter: Date | null;
  readonly nextSession: Session | null;
}

/** The provider's verification status and enrolment submission. */
@Injectable()
export class ProviderStatus {
  constructor(
    private readonly states: States,
    @Inject(PROVIDERS) private readonly providers: Providers,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}

  /** The provider's items, level and Level 2 situation. */
  async status(id: string): Promise<Status> {
    const st = await this.states.repo.load(id);
    const rules = await this.settings.rules();
    const retry = retryAfter(st.sessions, rules.level2CoolingOffMs, this.states.clock.now());
    return {
      ...st,
      canReceiveBookings: canReceiveBookings(st, 1),
      level2Eligible: st.level === 1 && retry === null,
      retryAfter: retry,
      nextSession: st.sessions.findLast((s) => s.status === 'scheduled') ?? null,
    };
  }

  /** Sends the enrolment to the review queue once every required step is done. */
  async submit(id: string): Promise<Status> {
    await this.providers.markSubmitted(id);
    const p = await this.providers.get(id);
    const now = this.states.clock.now();
    await this.states.repo.change(id, (st) => {
      st.submittedAt = now;
      st.serviceIds = [...p.serviceIds];
      return [];
    });
    return this.status(id);
  }
}
