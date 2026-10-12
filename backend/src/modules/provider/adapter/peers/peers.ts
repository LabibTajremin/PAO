import { Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { DomainError, isDomainError } from '../../../../platform/errors/domain-error';
import { ADMIN_SERVICE, type AdminService } from '../../../admin/contract/admin-service';
import { CATALOG_SERVICE, type CatalogService } from '../../../catalog/contract/catalog-service';
import { CatalogErrors } from '../../../catalog/contract/errors';
import { CodePurpose } from '../../../identity/contract/dto';
import { IdentityErrors } from '../../../identity/contract/errors';
import {
  IDENTITY_SERVICE,
  type IdentityService,
} from '../../../identity/contract/identity-service';
import { MediaPurpose } from '../../../media/contract/dto';
import { MediaErrors } from '../../../media/contract/errors';
import { MEDIA_SERVICE, type MediaService } from '../../../media/contract/media-service';
import { RATING_SERVICE, type RatingService } from '../../../rating/contract/rating-service';
import { ProviderReasons } from '../../domain/reasons';
import {
  type Accounts,
  type Catalog,
  type Media,
  type Quality,
  type Rating,
  type Ratings,
  type Service,
  type Settings,
} from '../../port/peers';

// Contracts are resolved on first use, so the provider module starts whichever peers
// are wired and breaks the cycle with verification and identity.

/** Reads services through the catalog contract. */
@Injectable()
export class CatalogServices implements Catalog {
  private readonly catalog: LazyContract<CatalogService>;

  constructor(ref: ModuleRef) {
    this.catalog = new LazyContract(ref, CATALOG_SERVICE);
  }

  /** The minimum level is raised to 2 when the service demands Level 2 (PRD §6.1). */
  async service(id: string): Promise<Service> {
    try {
      const s = await this.catalog.get().getService(id);
      const minLevel = s.requiresLevel2 ? 2 : s.requiredLevel;
      const { name, published, womenProvidersOnly } = s;
      return { id: s.id, name, published, minLevel, womenProvidersOnly };
    } catch (err) {
      if (isDomainError(err, CatalogErrors.ServiceNotFound)) {
        throw new DomainError(ProviderReasons.UnknownService, { cause: err });
      }
      throw err;
    }
  }
}

function codeError(err: unknown): Error {
  if (isDomainError(err, IdentityErrors.RateLimited)) {
    return new DomainError(ProviderReasons.CodeRateLimited, { cause: err });
  }
  const rejected = [
    IdentityErrors.CodeInvalid,
    IdentityErrors.CodeExpired,
    IdentityErrors.CodeLocked,
  ];
  if (rejected.some((r) => isDomainError(err, r))) {
    return new DomainError(ProviderReasons.CodeRejected, { cause: err });
  }
  return err instanceof Error ? err : new Error(String(err));
}

/** Reaches accounts and one-time codes through the identity contract. */
@Injectable()
export class IdentityAccounts implements Accounts {
  private readonly identity: LazyContract<IdentityService>;

  constructor(ref: ModuleRef) {
    this.identity = new LazyContract(ref, IDENTITY_SERVICE);
  }

  async phone(id: string): Promise<string> {
    return (await this.identity.get().getAccount(id)).phone;
  }

  async sendContactCode(phone: string): Promise<void> {
    await this.identity
      .get()
      .sendPhoneCode(phone, CodePurpose.EmergencyContact)
      .catch((err: unknown) => {
        throw codeError(err);
      });
  }

  async checkContactCode(phone: string, code: string): Promise<void> {
    await this.identity
      .get()
      .checkPhoneCode(phone, CodePurpose.EmergencyContact, code)
      .catch((err: unknown) => {
        throw codeError(err);
      });
  }
}

/** Checks and shows the profile photo through the media contract. */
@Injectable()
export class MediaAvatars implements Media {
  private readonly media: LazyContract<MediaService>;

  constructor(ref: ModuleRef) {
    this.media = new LazyContract(ref, MEDIA_SERVICE);
  }

  async attachAvatar(owner: string, id: string): Promise<void> {
    const o = await this.media
      .get()
      .getObject(id)
      .catch((err: unknown) => {
        if (isDomainError(err, MediaErrors.NotFound)) {
          return undefined;
        }
        throw err;
      });
    if (o?.ownerId !== owner || o.purpose !== MediaPurpose.Avatar || !o.confirmed) {
      throw new DomainError(ProviderReasons.InvalidPhoto);
    }
    await this.media.get().markAttached(id);
  }

  async url(viewer: string, id: string): Promise<string> {
    const v = await this.media
      .get()
      .getViewUrl({ mediaId: id, viewerId: viewer, viewerRole: 'provider' });
    return v.url;
  }
}

/** Reads the quality thresholds through the admin contract. */
@Injectable()
export class AdminQuality implements Settings {
  private readonly admin: LazyContract<AdminService>;

  constructor(ref: ModuleRef) {
    this.admin = new LazyContract(ref, ADMIN_SERVICE);
  }

  async quality(): Promise<Quality> {
    const s = await this.admin.get().getSettings();
    return {
      ratingFloor: s.ratingFloor,
      ratingMinJobs: s.ratingMinJobs,
      maxCancellations: s.maxProviderCancellations30d,
    };
  }
}

/** Reads ratings through the rating contract. */
@Injectable()
export class ProviderRatings implements Ratings {
  private readonly rating: LazyContract<RatingService>;

  constructor(ref: ModuleRef) {
    this.rating = new LazyContract(ref, RATING_SERVICE);
  }

  providerRating(id: string): Promise<Rating> {
    return this.rating.get().getProviderRating(id);
  }
}
