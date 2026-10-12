import { DomainError } from '../../../platform/errors/domain-error';

/** Throws a `DomainError` with `reason` unless `ok`. */
export function check(ok: boolean, reason: string): void {
  if (!ok) {
    throw new DomainError(reason);
  }
}
