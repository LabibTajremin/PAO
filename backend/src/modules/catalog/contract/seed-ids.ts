import { v5 as uuidv5 } from 'uuid';

// Stable ids derived from seed keys make reseeding update rows instead of duplicating
// them; the namespace is the Go backend's, so both derive the same ids.
const SEED_NAMESPACE = '6b1f3c7e-2f4a-5d8e-9a0b-1c2d3e4f5a6b';

/** The stable id of a seed item, e.g. `seedId('service', 'electrician')`. */
export function seedId(kind: 'category' | 'service' | 'sub-service', key: string): string {
  return uuidv5(`${kind}/${key}`, SEED_NAMESPACE);
}
