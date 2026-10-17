import { type components } from '../../../../platform/http/openapi.gen';
import { type Review } from '../../app/review';
import { ITEM_TYPES, ItemStatus } from '../../domain/items';
import { itemOf } from '../../domain/state';
import { itemView } from './views';

type Schemas = components['schemas'];

/** The profile data a verifier checks for each profile item. */
function profileFields(r: Review): Record<string, Record<string, string>> {
  const p = r.provider;
  const area: Record<string, string> = {
    workingRadiusM: String(p.workingRadiusM),
    services: String(p.serviceIds.length),
  };
  if (p.homeBase !== null) {
    area.homeLat = p.homeBase.lat.toFixed(6);
    area.homeLng = p.homeBase.lng.toFixed(6);
  }
  const out: Record<string, Record<string, string>> = {
    address: { presentAddress: p.presentAddress, permanentAddress: p.permanentAddress },
    service_area: area,
  };
  const c = p.emergencyContact;
  if (c !== null) {
    out.emergency_contact = { name: c.name, relation: c.relation, phone: c.phone };
  }
  return out;
}

function profile(r: Review): Schemas['VerificationReview']['profile'] {
  const p = r.provider;
  return {
    fullName: p.fullName,
    // Go wrote its zero date for a provider who never saved the personal step.
    dateOfBirth: p.dateOfBirth?.toISOString().slice(0, 10) ?? '0001-01-01',
    gender: p.gender,
    phone: p.phone,
    presentAddress: p.presentAddress,
    permanentAddress: p.permanentAddress,
    ...(r.nidNumber === '' ? {} : { nidNumber: r.nidNumber }),
  };
}

/** Everything a verifier sees for one provider (A06). */
export function reviewView(r: Review): Schemas['VerificationReview'] {
  const extra = profileFields(r);
  const items = ITEM_TYPES.map((t) => {
    const it = itemOf(r, t);
    const documents = r.documents
      .filter((d) => d.itemType === t)
      .map((d) => ({ mediaId: d.mediaId, kind: d.kind }));
    return { ...itemView(it), fields: { ...it.fields, ...extra[t] }, documents };
  });
  const selfieSent = itemOf(r, 'selfie').status !== ItemStatus.Missing;
  return {
    providerId: r.provider.id,
    level: r.level,
    profile: profile(r),
    faceMatch: selfieSent ? 'manual_review' : 'not_run',
    items,
  };
}
