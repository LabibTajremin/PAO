import { type components } from '../../../../platform/http/openapi.gen';
import { HEARTBEAT_EVERY_S } from '../../app/presence';
import { type Profile, type PublicProfile } from '../../app/profile';
import { type Progress } from '../../domain/enrolment';
import { badge } from '../../domain/provider';
import { type Service } from '../../port/peers';

type Schemas = components['schemas'];

/** The wizard progress as the API shows it. */
export function enrolmentView(p: Progress): Schemas['EnrolmentStatus'] {
  return { ...p, steps: p.steps as Schemas['EnrolmentStatus']['steps'] };
}

function serviceRef(s: Service): Schemas['ServiceRef'] {
  return { id: s.id, name: { en: s.name.en, bn: s.name.bn } };
}

/** The provider's own profile (M28). */
export function profileView(p: Profile): Schemas['ProviderProfile'] {
  return {
    id: p.id,
    name: p.fullName,
    phone: p.phone,
    ...(p.photoUrl === '' ? {} : { photoUrl: p.photoUrl }),
    bio: p.bio,
    status: p.accountStatus as Schemas['AccountStatus'],
    level: p.level,
    badge: badge(p.level),
    online: p.online,
    language: p.language as Schemas['Language'],
    services: p.services.map(serviceRef),
    experienceYears: p.experienceYears,
    ...(p.homeBase === null ? {} : { homeBase: p.homeBase, workingRadiusM: p.workingRadiusM }),
    flaggedForReview: p.flagged,
  };
}

/** What customers see of a provider (C11). */
export function publicProfileView(p: PublicProfile): Schemas['ProviderPublicProfile'] {
  const distribution = Object.fromEntries(p.rating.distribution.map((n, i) => [String(i + 1), n]));
  return {
    id: p.id,
    name: p.fullName,
    ...(p.photoUrl === '' ? {} : { photoUrl: p.photoUrl }),
    badge: badge(p.level),
    level: p.level,
    bio: p.bio,
    experienceYears: p.experienceYears,
    services: p.services.map(serviceRef),
    rating: { average: p.rating.average, count: p.rating.count, distribution },
    completedJobs: p.completedJobs,
    memberSince: p.createdAt.toISOString(),
  };
}

/** Presence with the heartbeat interval the app should keep. */
export function presenceView(online: boolean): Schemas['PresenceState'] {
  return { online, heartbeatIntervalSeconds: HEARTBEAT_EVERY_S };
}
