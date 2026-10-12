/** A decoded JSON object. */
export type Json = Record<string, unknown>;

/** Narrows a decoded value to an object, failing loudly when the API sent otherwise. */
export function obj(value: unknown): Json {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error(`want an object, got ${JSON.stringify(value)}`);
  }
  return value as Json;
}

/** Narrows a decoded value to an array of objects. */
export function list(value: unknown): Json[] {
  if (!Array.isArray(value)) {
    throw new Error(`want an array, got ${JSON.stringify(value)}`);
  }
  return value.map(obj);
}

/** Narrows a decoded value to a string. */
export function str(value: unknown): string {
  if (typeof value !== 'string') {
    throw new Error(`want a string, got ${JSON.stringify(value)}`);
  }
  return value;
}
