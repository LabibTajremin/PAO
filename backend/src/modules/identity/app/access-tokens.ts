import { Inject, Injectable } from '@nestjs/common';
import { type AccessClaims, TokenSigner } from '../../../platform/auth/access-token';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { RbacChecker } from '../../../platform/rbac/rbac';
import { Denylist } from '../../../platform/redis/denylist';
import { type Account } from '../domain/account';
import { type Permissions, type Revoker, type Signer } from '../port/outside-world';

/**
 * Signs access tokens at the current RBAC version, so a role change outdates them, and
 * revokes live ones until they would have expired.
 */
@Injectable()
export class AccessTokens {
  constructor(
    @Inject(TokenSigner) private readonly signer: Signer,
    @Inject(RbacChecker) private readonly rbac: Permissions,
    @Inject(Denylist) private readonly denylist: Revoker,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** Signs a token for the account on the session (refresh family) `sessionId`. */
  async sign(a: Account, sessionId: string): Promise<{ token: string; claims: AccessClaims }> {
    const version = await this.rbac.version();
    return this.signer.sign({ subject: a.id, roles: a.roles, sessionId, version });
  }

  /** Revokes the token `tokenId`, which expires at `expiresAt`. */
  revoke(tokenId: string, expiresAt: Date): Promise<void> {
    return this.denylist.deny(tokenId, expiresAt.getTime() - this.clock.now().getTime());
  }
}
