import { type ModuleRef } from '@nestjs/core';

/**
 * Another module's contract, resolved on first use instead of at construction. It breaks
 * a dependency cycle between modules (identity reads provider levels from verification,
 * which depends on identity): inject `ModuleRef` and call `get()` inside a method.
 */
export class LazyContract<T> {
  private resolved?: T;

  constructor(
    private readonly moduleRef: ModuleRef,
    private readonly token: symbol,
  ) {}

  /** The contract; resolved once, on the first call. */
  get(): T {
    this.resolved ??= this.moduleRef.get<T>(this.token, { strict: false });
    return this.resolved;
  }
}
