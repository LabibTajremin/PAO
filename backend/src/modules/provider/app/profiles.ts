import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { isDomainError } from '../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { type EnrolmentStepSaved, ProviderEvents } from '../contract/events';
import { type EnrolmentStep } from '../contract/enrolment';
import { type Progress, progress, withStep } from '../domain/enrolment';
import { type Provider } from '../domain/provider';
import { ProviderReasons } from '../domain/reasons';
import { ACCOUNTS, type Accounts } from '../port/peers';
import { PROVIDER_REPOSITORY, type ProviderRepository } from '../port/repository';

/**
 * Steps saved here and reported to verification, which re-reviews the matching item
 * (PRD §6.4: changed data is checked again).
 */
const PROFILE_STEPS: readonly string[] = [
  'personal',
  'services',
  'area',
  'emergency_contact',
  'code_of_conduct',
];

/** Turns a profile into its wizard progress. */
export function progressOf(p: Provider): Progress {
  return progress(p.stepsDone, p.submittedAt !== null);
}

/** Loads and saves profiles for the enrolment and profile use cases. */
@Injectable()
export class Profiles {
  constructor(
    @Inject(PROVIDER_REPOSITORY) private readonly repo: ProviderRepository,
    @Inject(ACCOUNTS) private readonly accounts: Accounts,
    @Inject(CLOCK) readonly clock: Clock,
  ) {}

  /** Returns a profile, or throws `provider.not_found`. */
  get(id: string): Promise<Provider> {
    return this.repo.get(id);
  }

  /** Returns the profile, creating an empty one on the first enrolment call. */
  async load(id: string): Promise<Provider> {
    try {
      return await this.repo.get(id);
    } catch (err) {
      if (!isDomainError(err, ProviderReasons.NotFound)) {
        throw err;
      }
    }
    const phone = await this.accounts.phone(id);
    await this.repo.ensure(id, phone, this.clock.now());
    return this.repo.get(id);
  }

  /**
   * Loads the profile, applies `change`, marks `step` done (when given) and saves, with
   * EnrolmentStepSaved for profile steps.
   */
  async update(
    id: string,
    step: string | null,
    change: (p: Provider) => Promise<Provider> | Provider,
  ): Promise<Progress> {
    let p = await change(await this.load(id));
    const events: DomainEvent[] = [];
    if (step !== null) {
      p = { ...p, stepsDone: withStep(p.stepsDone, step) };
      if (PROFILE_STEPS.includes(step)) {
        events.push(stepSaved(id, step as EnrolmentStep));
      }
    }
    await this.repo.save(p, events);
    return progressOf(p);
  }
}

function stepSaved(providerId: string, step: EnrolmentStep): EnrolmentStepSaved {
  return { name: ProviderEvents.EnrolmentStepSaved, providerId, step };
}
