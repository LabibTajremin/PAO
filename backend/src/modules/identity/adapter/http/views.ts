import { type components } from '../../../../platform/http/openapi.gen';
import { type Admin } from '../../domain/admin';
import { type Account } from '../../domain/account';
import { type RoleDefinition } from '../../app/role-editor';
import { type Session } from '../../app/sessions';

type Schemas = components['schemas'];

/** The API account; absent phone or email are left out. */
export function accountView(a: Account): Schemas['Account'] {
  return {
    id: a.id,
    ...(a.phone === '' ? {} : { phone: a.phone }),
    ...(a.email === '' ? {} : { email: a.email }),
    roles: a.roles as Schemas['Role'][],
    status: a.status,
    createdAt: a.createdAt.toISOString(),
  };
}

/** The token pair; the admin web app gets its refresh token as a cookie instead. */
export function tokenPair(s: Session, includeRefresh: boolean): Schemas['TokenPair'] {
  return {
    accessToken: s.accessToken,
    ...(includeRefresh ? { refreshToken: s.refreshToken } : {}),
    expiresInSeconds: s.expiresInMs / 1000,
    isNewAccount: s.isNewAccount,
    account: accountView(s.account),
  };
}

/** An admin user on the A-10 list. */
export function adminUserView(a: Admin): Schemas['AdminUser'] {
  return {
    id: a.id,
    email: a.email,
    name: a.name,
    roles: a.roles as Schemas['AdminRole'][],
    active: a.active,
    totpEnrolled: a.totpEnrolled,
    ...(a.lastLoginAt ? { lastLoginAt: a.lastLoginAt.toISOString() } : {}),
  };
}

/** A role with its grants. */
export function roleView(r: RoleDefinition): Schemas['RoleDefinition'] {
  return {
    role: r.role as Schemas['Role'],
    permissions: [...r.permissions],
    screens: [...r.screens],
  };
}

/** The admin refresh cookie; a zero `maxAgeMs` clears it. */
export function refreshCookie(token: string, maxAgeMs: number): string {
  const maxAge = Math.floor(maxAgeMs / 1000);
  return `pao_refresh=${token}; Path=/v1/auth; Max-Age=${maxAge}; HttpOnly; Secure; SameSite=Strict`;
}
