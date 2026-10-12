import { Inject, Injectable } from '@nestjs/common';
import { DomainError, isDomainError } from '../../../platform/errors/domain-error';
import {
  areaValid,
  dhakaDate,
  type Personal,
  personalProblem,
  type Progress,
  progress,
  servicesValid,
} from '../domain/enrolment';
import { type Point } from '../domain/provider';
import { ProviderReasons } from '../domain/reasons';
import { CATALOG, type Catalog } from '../port/peers';
import { PRESENCE, type Presence } from '../port/presence';
import { PROVIDER_REPOSITORY, type ProviderRepository } from '../port/repository';
import { Profiles, progressOf } from './profiles';

/** The resumable enrolment wizard (M05–M13): profile steps and submission. */
@Injectable()
export class Enrolment {
  constructor(
    private readonly profiles: Profiles,
    @Inject(PROVIDER_REPOSITORY) private readonly repo: ProviderRepository,
    @Inject(CATALOG) private readonly catalog: Catalog,
    @Inject(PRESENCE) private readonly presence: Presence,
  ) {}

  /** The wizard progress; nothing saved yet means every step is open. */
  async progress(id: string): Promise<Progress> {
    try {
      return progressOf(await this.repo.get(id));
    } catch (err) {
      if (isDomainError(err, ProviderReasons.NotFound)) {
        return progress([]);
      }
      throw err;
    }
  }

  /** Saves the M05 step. */
  savePersonal(id: string, input: Personal): Promise<Progress> {
    // Birthdays are Dhaka calendar dates (04-decisions E8), so today is one too.
    const problem = personalProblem(input, dhakaDate(this.profiles.clock.now()));
    if (problem !== undefined) {
      return Promise.reject(new DomainError(problem));
    }
    return this.profiles.update(id, 'personal', (p) => ({
      ...p,
      fullName: input.fullName.trim(),
      dateOfBirth: input.dateOfBirth,
      gender: input.gender,
      presentAddress: input.presentAddress,
      permanentAddress: input.permanentAddress,
      bio: input.bio,
    }));
  }

  /**
   * Saves the M06 step. Changing services takes the provider offline, so the presence
   * index never lists them under a service they dropped.
   */
  async saveServices(id: string, services: string[], experienceYears: number): Promise<Progress> {
    if (!servicesValid(services.length, experienceYears)) {
      throw new DomainError(ProviderReasons.Invalid);
    }
    for (const sid of services) {
      if (!(await this.catalog.service(sid)).published) {
        throw new DomainError(ProviderReasons.UnknownService);
      }
    }
    return this.profiles.update(id, 'services', async (p) => {
      await this.presence.offline(id, p.serviceIds);
      return { ...p, serviceIds: services, experienceYears };
    });
  }

  /** Saves the M07 step. */
  saveArea(id: string, home: Point, radiusM: number): Promise<Progress> {
    if (!areaValid(home, radiusM)) {
      return Promise.reject(new DomainError(ProviderReasons.Invalid));
    }
    return this.profiles.update(id, 'area', (p) => ({
      ...p,
      homeBase: home,
      workingRadiusM: radiusM,
    }));
  }

  /** Records the accepted version with a timestamp (PRD §6.2 item 9). */
  acceptCodeOfConduct(id: string, version: string, accepted: boolean): Promise<Progress> {
    if (!accepted || version.trim() === '') {
      return Promise.reject(new DomainError(ProviderReasons.Invalid));
    }
    return this.profiles.update(id, 'code_of_conduct', (p) => ({
      ...p,
      cocVersion: version,
      cocAcceptedAt: this.profiles.clock.now(),
    }));
  }

  /** Records a document step saved by verification. */
  markStepDone(id: string, step: string): Promise<Progress> {
    return this.profiles.update(id, step, (p) => p);
  }

  /** Records that the enrolment went to review; every required step must be done. */
  async markSubmitted(id: string): Promise<void> {
    const p = await this.profiles.load(id);
    if (!progressOf(p).complete) {
      throw new DomainError(ProviderReasons.EnrolmentIncomplete);
    }
    await this.repo.save({ ...p, submittedAt: this.profiles.clock.now() });
  }
}
