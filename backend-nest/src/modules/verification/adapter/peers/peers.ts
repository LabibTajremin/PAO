import { Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { DomainError, isDomainError } from '../../../../platform/errors/domain-error';
import { ADMIN_SERVICE, type AdminService } from '../../../admin/contract/admin-service';
import { CATALOG_SERVICE, type CatalogService } from '../../../catalog/contract/catalog-service';
import { CatalogErrors } from '../../../catalog/contract/errors';
import { MediaErrors } from '../../../media/contract/errors';
import { MEDIA_SERVICE, type MediaService } from '../../../media/contract/media-service';
import { type Provider } from '../../../provider/contract/dto';
import { type EnrolmentStatus, type EnrolmentStep } from '../../../provider/contract/enrolment';
import { ProviderErrors } from '../../../provider/contract/errors';
import {
  PROVIDER_SERVICE,
  type ProviderService,
} from '../../../provider/contract/provider-service';
import { VerificationReasons } from '../../domain/reasons';
import {
  type Catalog,
  type Media,
  type Providers,
  type Rules,
  type Service,
  type Settings,
} from '../../port/peers';

// Contracts are resolved on first use: verification and provider depend on each other.

async function translated<T>(call: Promise<T>, from: string, to: string): Promise<T> {
  try {
    return await call;
  } catch (err) {
    throw isDomainError(err, from) ? new DomainError(to, { cause: err }) : err;
  }
}

/** Reaches the provider module through its contract. */
@Injectable()
export class ProviderProfiles implements Providers {
  private readonly providers: LazyContract<ProviderService>;

  constructor(ref: ModuleRef) {
    this.providers = new LazyContract(ref, PROVIDER_SERVICE);
  }

  get(id: string): Promise<Provider> {
    const call = this.providers.get().getProvider(id);
    return translated(call, ProviderErrors.NotFound, VerificationReasons.NotFound);
  }

  markStepDone(id: string, step: EnrolmentStep): Promise<EnrolmentStatus> {
    return this.providers.get().markStepDone(id, step);
  }

  markSubmitted(id: string): Promise<void> {
    const call = this.providers.get().markSubmitted(id);
    const { EnrolmentIncomplete } = ProviderErrors;
    return translated(call, EnrolmentIncomplete, VerificationReasons.EnrolmentPending);
  }
}

/** Checks document uploads through the media contract. */
@Injectable()
export class MediaDocuments implements Media {
  private readonly media: LazyContract<MediaService>;

  constructor(ref: ModuleRef) {
    this.media = new LazyContract(ref, MEDIA_SERVICE);
  }

  async attach(owner: string, id: string, purposes: readonly string[]): Promise<void> {
    const o = await this.media
      .get()
      .getObject(id)
      .catch((err: unknown) => {
        if (isDomainError(err, MediaErrors.NotFound)) {
          return undefined;
        }
        throw err;
      });
    if (o?.ownerId !== owner || !o.confirmed || !purposes.includes(o.purpose)) {
      throw new DomainError(VerificationReasons.BadDocument);
    }
    await this.media.get().markAttached(id);
  }
}

/** Reads services through the catalog contract. */
@Injectable()
export class CatalogServices implements Catalog {
  private readonly catalog: LazyContract<CatalogService>;

  constructor(ref: ModuleRef) {
    this.catalog = new LazyContract(ref, CATALOG_SERVICE);
  }

  /** The minimum level is 2 when the service demands Level 2 (PRD §6.1). */
  async service(id: string): Promise<Service> {
    const call = this.catalog.get().getService(id);
    const s = await translated(call, CatalogErrors.ServiceNotFound, VerificationReasons.Invalid);
    return { id: s.id, name: s.name, minLevel: s.requiresLevel2 ? 2 : s.requiredLevel };
  }
}

/** Reads the verification rules through the admin contract. */
@Injectable()
export class AdminRules implements Settings {
  private readonly admin: LazyContract<AdminService>;

  constructor(ref: ModuleRef) {
    this.admin = new LazyContract(ref, ADMIN_SERVICE);
  }

  async rules(): Promise<Rules> {
    const s = await this.admin.get().getSettings();
    return {
      policeClearanceValidityMs: s.policeClearanceValidityMs,
      level2CoolingOffMs: s.level2CoolingOffMs,
    };
  }
}
