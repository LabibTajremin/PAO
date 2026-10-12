/** One admin-editable rule, stored as text and read through its type (A-10). */
export interface Setting {
  readonly key: string;
  readonly value: string;
  readonly type: string;
  readonly description: string;
  readonly updatedAt: Date;
  readonly updatedBy: string | null;
}

const INTEGER = /^[+-]?\d+$/;
const MAX_INT64 = 2n ** 63n;
// The decimal syntax Go's strconv.ParseFloat accepts; infinities are refused below.
const NUMBER = /^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/;
// The spellings Go's strconv.ParseBool accepts.
const BOOLEANS = new Set(['1', 't', 'T', 'TRUE', 'true', 'True']);
const FALSES = new Set(['0', 'f', 'F', 'FALSE', 'false', 'False']);

// Numbers must be non-negative: every setting is a duration, count, radius or threshold.
const validators: ReadonlyMap<string, (value: string) => boolean> = new Map([
  ['integer', (v: string) => INTEGER.test(v) && BigInt(v) >= 0n && BigInt(v) < MAX_INT64],
  ['number', (v: string) => NUMBER.test(v) && Number.isFinite(Number(v)) && Number(v) >= 0],
  ['boolean', (v: string) => BOOLEANS.has(v) || FALSES.has(v)],
  ['string', () => true],
  ['geojson', (v: string) => v === '' || isArea(v)],
]);

/** Reports whether a new value fits the setting's type. */
export function fitsSettingType(type: string, value: string): boolean {
  return validators.get(type)?.(value) === true;
}

/** A GeoJSON Polygon or MultiPolygon, the only shapes a service area can take (D5). */
function isArea(value: string): boolean {
  let shape: unknown;
  try {
    shape = JSON.parse(value);
  } catch {
    return false;
  }
  if (typeof shape !== 'object' || shape === null) {
    return false;
  }
  const { type, coordinates } = shape as { type?: unknown; coordinates?: unknown };
  return (
    (type === 'Polygon' || type === 'MultiPolygon') &&
    coordinates !== undefined &&
    JSON.stringify(coordinates).length > 2
  );
}
