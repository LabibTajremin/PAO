/**
 * A business-rule failure raised by a module's domain or use cases. `reason` is a stable,
 * module-scoped key (for example `booking.not_found`); only the module's HTTP adapter maps
 * it to an API error code (01-conventions.md §4).
 */
export class DomainError extends Error {
  constructor(
    readonly reason: string,
    options?: ErrorOptions,
  ) {
    super(reason, options);
    this.name = 'DomainError';
  }
}

/** Reports whether `err` is a {@link DomainError} with the given reason. */
export function isDomainError(err: unknown, reason: string): err is DomainError {
  return err instanceof DomainError && err.reason === reason;
}
