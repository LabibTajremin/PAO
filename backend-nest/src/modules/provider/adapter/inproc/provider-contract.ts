import { Injectable } from '@nestjs/common';
import { type Language } from '../../../../platform/i18n/text';
import { Enrolment } from '../../app/enrolment';
import { FindProviders } from '../../app/find-nearby';
import { ManagePresence } from '../../app/presence';
import { Profiles } from '../../app/profiles';
import { type ProviderQuery, type ProviderRecord } from '../../contract/admin-search';
import {
  type Gender,
  type NearbyProvider,
  type NearbyQuery,
  type Provider,
  SortOrder,
} from '../../contract/dto';
import {
  type EnrolmentStatus,
  type EnrolmentStep,
  type StepStatus,
} from '../../contract/enrolment';
import { type ProviderService } from '../../contract/provider-service';
import { type Progress } from '../../domain/enrolment';

function status(p: Progress): EnrolmentStatus {
  return { ...p, steps: p.steps as StepStatus[] };
}

/** The provider contract for other modules in the process. */
@Injectable()
export class ProviderContract implements ProviderService {
  constructor(
    private readonly profiles: Profiles,
    private readonly enrolments: Enrolment,
    private readonly presence: ManagePresence,
    private readonly finder: FindProviders,
  ) {}

  async getProvider(providerId: string): Promise<Provider> {
    const p = await this.profiles.get(providerId);
    return {
      id: p.id,
      fullName: p.fullName,
      dateOfBirth: p.dateOfBirth,
      gender: p.gender as Gender,
      presentAddress: p.presentAddress,
      permanentAddress: p.permanentAddress,
      phone: p.phone,
      photoMediaId: p.photoMediaId,
      serviceIds: p.serviceIds,
      experienceYears: p.experienceYears,
      homeBase: p.homeBase,
      workingRadiusM: p.workingRadiusM,
      language: p.language as Language,
      emergencyContact: p.emergency.phone === '' ? null : p.emergency,
      submittedAt: p.submittedAt,
    };
  }

  isAvailable(providerId: string): Promise<boolean> {
    return this.presence.isAvailable(providerId);
  }

  async findNearby(q: NearbyQuery): Promise<NearbyProvider[]> {
    const found = await this.finder.nearby({
      serviceId: q.serviceId,
      at: q.point,
      radiusM: q.radiusM,
      womenOnly: q.womenProvidersOnly,
      byRating: q.sort === SortOrder.Rating,
      limit: q.limit,
    });
    return found.map(({ id, gender: _gender, ...c }) => ({ providerId: id, ...c }));
  }

  async enrolment(providerId: string): Promise<EnrolmentStatus> {
    return status(await this.enrolments.progress(providerId));
  }

  async markStepDone(providerId: string, step: EnrolmentStep): Promise<EnrolmentStatus> {
    return status(await this.enrolments.markStepDone(providerId, step));
  }

  markSubmitted(providerId: string): Promise<void> {
    return this.enrolments.markSubmitted(providerId);
  }

  forceOffline(providerId: string): Promise<void> {
    return this.presence.goOffline(providerId, 'forced');
  }

  searchProviders(query: ProviderQuery): Promise<ProviderRecord[]> {
    return this.finder.search(query);
  }
}
