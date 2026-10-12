import { Inject, Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { VERIFICATION_SERVICE, type VerificationService } from '../../../verification/contract';
import { type LevelReader } from '../../port/outside-world';

/**
 * Reads provider levels from verification. Verification depends on modules that depend
 * on identity, so its contract is resolved on first use.
 */
@Injectable()
export class VerificationLevels implements LevelReader {
  private readonly verification: LazyContract<VerificationService>;

  constructor(@Inject(ModuleRef) moduleRef: ModuleRef) {
    this.verification = new LazyContract(moduleRef, VERIFICATION_SERVICE);
  }

  getLevel(providerId: string): Promise<number> {
    return this.verification.get().getLevel(providerId);
  }
}
