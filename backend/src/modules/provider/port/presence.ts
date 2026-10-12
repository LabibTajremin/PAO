import { type Point } from '../domain/provider';

/** A provider position found by the presence index. */
export interface Hit {
  readonly id: string;
  readonly distanceM: number;
}

/**
 * Tracks online providers and their live position (PRD §11: never stored while
 * offline).
 */
export interface Presence {
  online(id: string, services: readonly string[], at: Point): Promise<void>;
  /** Refreshes the position; throws `provider.offline` when not online. */
  beat(id: string, services: readonly string[], at: Point): Promise<void>;
  offline(id: string, services: readonly string[]): Promise<void>;
  isOnline(id: string): Promise<boolean>;
  near(service: string, at: Point, radiusM: number): Promise<Hit[]>;
  /** Providers marked online whose heartbeat has lapsed. */
  lost(): Promise<string[]>;
}

/** Injection token for the {@link Presence}. */
export const PRESENCE = Symbol('Presence');
