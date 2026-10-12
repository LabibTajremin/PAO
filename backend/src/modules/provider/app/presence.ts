import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { ProviderEvents, type ProviderWentOffline } from '../contract/events';
import { cannotGoOnline, type Point } from '../domain/provider';
import { PRESENCE, type Presence } from '../port/presence';
import { PROVIDER_REPOSITORY, type ProviderRepository } from '../port/repository';

/** How often an online app reports its position, in seconds. */
export const HEARTBEAT_EVERY_S = 30;

/** Online, heartbeat and offline for providers (PRD §6.1, §11). */
@Injectable()
export class ManagePresence {
  constructor(
    @Inject(PROVIDER_REPOSITORY) private readonly repo: ProviderRepository,
    @Inject(PRESENCE) private readonly presence: Presence,
  ) {}

  /** Puts a verified provider into the presence index at their position. */
  async goOnline(id: string, at: Point): Promise<void> {
    const p = await this.repo.get(id);
    const refusal = cannotGoOnline(p);
    if (refusal !== undefined) {
      throw new DomainError(refusal);
    }
    await this.presence.online(id, p.serviceIds, at);
  }

  /** Refreshes an online provider's position. */
  async heartbeat(id: string, at: Point): Promise<void> {
    const p = await this.repo.get(id);
    await this.presence.beat(id, p.serviceIds, at);
  }

  /** Removes the provider from presence; their position is dropped with it. */
  async goOffline(id: string, reason: string): Promise<void> {
    const p = await this.repo.get(id);
    await this.presence.offline(id, p.serviceIds);
    const event: ProviderWentOffline = {
      name: ProviderEvents.ProviderWentOffline,
      providerId: id,
      reason,
    };
    await this.repo.publish(id, [event]);
  }

  /** Takes providers whose heartbeat lapsed offline. */
  async reapLost(): Promise<void> {
    for (const id of await this.presence.lost()) {
      await this.goOffline(id, 'heartbeat_lost');
    }
  }

  /** Reports whether the provider is online now. */
  isAvailable(id: string): Promise<boolean> {
    return this.presence.isOnline(id);
  }
}
