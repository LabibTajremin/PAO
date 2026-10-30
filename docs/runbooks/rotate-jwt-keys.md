# Rotate the JWT signing key

**When:** once a year, when someone who had access to the secret store leaves, or at
once if the key may have leaked (then follow "Emergency rotation" below).

## How keys work

Access tokens are EdDSA (Ed25519) JWTs valid for 15 minutes. Their header names the key
id (`kid`). The API signs with one key and verifies against it plus a list of previous
public keys:

| Variable | Holds |
|---|---|
| `JWT_SIGNING_KEY` | base64 of the 32-byte Ed25519 seed (secret) |
| `JWT_KEY_ID` | its key id, e.g. `k2026` |
| `JWT_PREVIOUS_PUBLIC_KEYS` | comma-separated `kid:base64-public-key` entries still accepted |

Refresh tokens are opaque random values stored hashed in Redis; rotating the signing key
does not touch them, so nobody is signed out by a planned rotation.

## Planned rotation

1. **Derive the current key's public key** (on a trusted machine; the secret stays in
   the environment variable, not on the command line):

   ```sh
   OLD_KEY='<current JWT_SIGNING_KEY>' node -e "
     const c = require('crypto');
     const seed = Buffer.from(process.env.OLD_KEY, 'base64');
     const der = Buffer.concat([Buffer.from('302e020100300506032b657004220420', 'hex'), seed]);
     const pub = c.createPublicKey(c.createPrivateKey({ key: der, format: 'der', type: 'pkcs8' }));
     console.log(pub.export({ format: 'der', type: 'spki' }).subarray(12).toString('base64'));"
   ```

2. **Generate the new key:** `head -c 32 /dev/urandom | base64`. Pick a new key id that
   was never used (e.g. the year and month, `k202611`).
3. **Update the secret store** for the API (the worker does not sign tokens, but keep
   its environment identical):
   - `JWT_SIGNING_KEY` = the new seed
   - `JWT_KEY_ID` = the new id
   - `JWT_PREVIOUS_PUBLIC_KEYS` = `<old kid>:<old public key>` (keep any entry younger
     than 15 minutes, drop older ones)
4. **Roll the API** ([deploy.md](deploy.md), step 5, same image). During the roll, old
   instances still sign with the old key; new instances accept both, so no request
   fails.
5. **Check:** sign in on staging and production; `401 UNAUTHENTICATED` must not rise on
   the PAO API dashboard ("4xx by route").
6. **After 15 minutes** (and once every old instance is gone) remove the old entry from
   `JWT_PREVIOUS_PUBLIC_KEYS` and roll the API again. Destroy every copy of the old seed.

## Emergency rotation (key leaked)

A leaked key lets anyone mint access tokens for any account until it is no longer
accepted, so do not keep it as a previous key:

1. Generate the new key and id; set `JWT_PREVIOUS_PUBLIC_KEYS` to empty.
2. Roll every API instance at once (accept the brief error spike).
3. Every access token becomes invalid; the apps refresh with their refresh tokens and
   continue. Admins sign in again in the worst case.
4. If the attacker may also have read Redis, revoke all sessions: flush the refresh token
   families so everyone signs in again (keys are prefixed `pao:{env}:`, see
   `docs/build/02-architecture.md` §4):

   ```sh
   for p in 'pao:prod:rt:*' 'pao:prod:sess:*'; do
     redis-cli -u "$REDIS_URL" --scan --pattern "$p" | xargs -r -n 500 redis-cli -u "$REDIS_URL" DEL
   done
   ```
5. Review the audit log (`audit.entries`) for admin actions in the exposure window.

## Not covered here

`DATA_ENCRYPTION_KEY` (AES-GCM for NID numbers and TOTP secrets) has its own runbook:
[rotate-data-key.md](rotate-data-key.md).
