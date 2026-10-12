/** Closed accounts whose verification records wait out the retention period. */
export interface Closures {
  /** Remembers the first closure; a redelivered event keeps the original time. */
  record(providerId: string, closedAt: Date): Promise<void>;
  /** Accounts closed before `cutoff`, oldest first, a batch at a time. */
  closedBefore(cutoff: Date): Promise<string[]>;
  /** The Level 2 visit photos kept for the provider; verifiers uploaded them. */
  level2Photos(providerId: string): Promise<string[]>;
  /** Deletes every verification record of the provider, closure included. */
  purge(providerId: string): Promise<void>;
}

/** Deletes stored files once their retention ends. */
export interface Files {
  /** Every file the account uploaded. */
  deleteOwned(ownerId: string): Promise<void>;
  /** One file; an already deleted one is not an error, so a retried purge goes on. */
  delete(mediaId: string): Promise<void>;
}

/** Injection token for the {@link Closures}. */
export const CLOSURES = Symbol('VerificationClosures');
/** Injection token for the {@link Files}. */
export const FILES = Symbol('VerificationFiles');
