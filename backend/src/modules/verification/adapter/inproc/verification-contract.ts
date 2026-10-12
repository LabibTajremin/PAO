import { Injectable } from '@nestjs/common';
import { States } from '../../app/states';
import { type Item } from '../../contract/dto';
import { type VerificationService } from '../../contract/verification-service';

/** The verification contract for other modules in the process. */
@Injectable()
export class VerificationContract implements VerificationService {
  constructor(private readonly states: States) {}

  getLevel(providerId: string): Promise<number> {
    return this.states.level(providerId);
  }

  getLevels(providerIds: readonly string[]): Promise<Map<string, number>> {
    return this.states.levels(providerIds);
  }

  canReceiveBookings(providerId: string, serviceId: string | null): Promise<boolean> {
    return this.states.canReceiveBookings(providerId, serviceId);
  }

  getItems(providerId: string): Promise<Item[]> {
    return this.states.items(providerId);
  }

  countPendingReviews(): Promise<number> {
    return this.states.countPendingReviews();
  }
}
