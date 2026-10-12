import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { length } from '../domain/enrolment';
import { type Provider } from '../domain/provider';
import { ProviderReasons } from '../domain/reasons';
import {
  CATALOG,
  type Catalog,
  MEDIA,
  type Media,
  type Rating,
  RATINGS,
  type Ratings,
  type Service,
} from '../port/peers';
import { PRESENCE, type Presence } from '../port/presence';
import { Profiles } from './profiles';

/** The provider's own view (M28). */
export interface Profile extends Provider {
  readonly online: boolean;
  readonly photoUrl: string;
  readonly services: Service[];
}

/** What customers see of a provider (C11): never documents or contacts. */
export interface PublicProfile extends Provider {
  readonly photoUrl: string;
  readonly services: Service[];
  readonly rating: Rating;
}

/** Changes to the provider's own profile. */
export interface ProfileChange {
  readonly bio: string;
  readonly photoMediaId: string | null;
  readonly language: string;
}

/** The photo URL and service names every profile view shows. */
async function shown(catalog: Catalog, media: Media, viewer: string, p: Provider) {
  const photoUrl = p.photoMediaId === null ? '' : await media.url(viewer, p.photoMediaId);
  const services: Service[] = [];
  for (const sid of p.serviceIds) {
    services.push(await catalog.service(sid));
  }
  return { photoUrl, services };
}

/** The provider's own profile (M28). */
@Injectable()
export class ProviderProfiles {
  constructor(
    private readonly profiles: Profiles,
    @Inject(PRESENCE) private readonly presence: Presence,
    @Inject(CATALOG) private readonly catalog: Catalog,
    @Inject(MEDIA) private readonly media: Media,
  ) {}

  /** Returns the provider's profile with presence and photo. */
  async own(id: string): Promise<Profile> {
    const p = await this.profiles.load(id);
    const online = await this.presence.isOnline(id);
    return { ...p, online, ...(await shown(this.catalog, this.media, id, p)) };
  }

  /** Changes the bio, photo and language. */
  async update(id: string, c: ProfileChange): Promise<Profile> {
    if (length(c.bio) > 500 || (c.language !== 'en' && c.language !== 'bn')) {
      throw new DomainError(ProviderReasons.Invalid);
    }
    await this.profiles.update(id, null, async (p) => {
      if (c.photoMediaId !== null) {
        await this.media.attachAvatar(id, c.photoMediaId);
      }
      return { ...p, bio: c.bio, photoMediaId: c.photoMediaId, language: c.language };
    });
    return this.own(id);
  }
}

/** The profile customers see (C11). */
@Injectable()
export class PublicProfiles {
  constructor(
    private readonly profiles: Profiles,
    @Inject(CATALOG) private readonly catalog: Catalog,
    @Inject(MEDIA) private readonly media: Media,
    @Inject(RATINGS) private readonly ratings: Ratings,
  ) {}

  /** Returns a verified, active provider's public profile. */
  async get(viewer: string, id: string): Promise<PublicProfile> {
    const p = await this.profiles.get(id);
    if (p.level < 1 || p.accountStatus !== 'active') {
      throw new DomainError(ProviderReasons.NotFound);
    }
    const view = await shown(this.catalog, this.media, viewer, p);
    return { ...p, ...view, rating: await this.ratings.providerRating(id) };
  }
}
