import { NIL as NIL_UUID } from 'uuid';
import { type Envelope } from './event-bus';

/**
 * Reads another module's event the way Go's JSON decoding did: a missing field is its
 * zero value (the nil UUID for ids), while a field of the wrong type or a payload that is
 * not an object fails, so the relay retries the event.
 */
export class Payload {
  private readonly fields: Readonly<Record<string, unknown>>;

  constructor(private readonly env: Envelope) {
    const p: unknown = env.payload;
    if (typeof p !== 'object' || p === null || Array.isArray(p)) {
      throw new Error(`decode ${env.name}: payload is not an object`);
    }
    this.fields = p as Readonly<Record<string, unknown>>;
  }

  private read<T>(name: string, type: string, zero: T): T {
    const v = this.fields[name];
    if (v === undefined || v === null) {
      return zero;
    }
    if (typeof v !== type) {
      throw new Error(`decode ${this.env.name}: ${name} is not a ${type}`);
    }
    return v as T;
  }

  /** A UUID field; the nil UUID when missing. */
  id(name: string): string {
    return this.read(name, 'string', NIL_UUID);
  }

  /** A string field; empty when missing. */
  text(name: string): string {
    return this.read(name, 'string', '');
  }

  /** A number field; 0 when missing. */
  number(name: string): number {
    return this.read(name, 'number', 0);
  }

  /** A boolean field; false when missing. */
  flag(name: string): boolean {
    return this.read(name, 'boolean', false);
  }
}
