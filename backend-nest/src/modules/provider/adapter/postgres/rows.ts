import { type Provider } from '../../domain/provider';
import { type ProviderByIDRow, type SaveProfileArgs } from './sqlc/queries_sql';

/**
 * node-postgres reads a `date` column as local midnight; birthdays are calendar dates,
 * so they are kept as UTC midnight like the API's "YYYY-MM-DD".
 */
function calendarDate(d: Date | null): Date | null {
  return d === null ? null : new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
}

/** A stored profile. */
export function toProvider(r: ProviderByIDRow): Provider {
  return {
    ...r,
    dateOfBirth: calendarDate(r.dateOfBirth),
    gender: r.gender ?? '',
    homeBase: r.hasHomeBase ? { lat: r.homeLat, lng: r.homeLng } : null,
    emergency: {
      name: r.emergencyName,
      relation: r.emergencyRelation,
      phone: r.emergencyPhone,
      verifiedAt: r.emergencyVerifiedAt,
    },
    flagged: r.flaggedForReview,
  };
}

/** The profile fields a save writes; read-model copies are left alone. */
export function saveArgs(p: Provider, at: Date): SaveProfileArgs {
  return {
    id: p.id,
    fullName: p.fullName,
    dateOfBirth: p.dateOfBirth,
    gender: p.gender === '' ? null : p.gender,
    presentAddress: p.presentAddress,
    permanentAddress: p.permanentAddress,
    bio: p.bio,
    photoMediaId: p.photoMediaId,
    experienceYears: p.experienceYears,
    language: p.language,
    hasHomeBase: p.homeBase !== null,
    homeLat: p.homeBase?.lat ?? 0,
    homeLng: p.homeBase?.lng ?? 0,
    workingRadiusM: p.workingRadiusM,
    emergencyName: p.emergency.name,
    emergencyRelation: p.emergency.relation,
    emergencyPhone: p.emergency.phone,
    emergencyVerifiedAt: p.emergency.verifiedAt,
    cocVersion: p.cocVersion,
    cocAcceptedAt: p.cocAcceptedAt,
    stepsDone: [...p.stepsDone],
    submittedAt: p.submittedAt,
    updatedAt: at,
  };
}
