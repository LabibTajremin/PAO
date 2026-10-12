/** The authenticated caller, read from a verified access token. */
export interface Principal {
  readonly accountId: string;
  readonly roles: readonly string[];
  /** The access token id (`jti`), for logout and revocation. */
  readonly tokenId: string;
  /** The refresh-token family (device) the token belongs to. */
  readonly sessionId: string;
  readonly expiresAt: Date;
}

/** Reports whether the principal holds `role`. */
export function hasRole(p: Principal, role: string): boolean {
  return p.roles.includes(role);
}
