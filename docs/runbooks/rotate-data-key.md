# Rotate the data encryption key

**When:** when someone who had access to the secret store leaves, or at once if
`DATA_ENCRYPTION_KEY` may have leaked. Not on a schedule: every rotation lengthens
`DATA_ENCRYPTION_PREVIOUS_KEYS` by one key that must be kept.

## How the key works

`DATA_ENCRYPTION_KEY` (32 bytes, base64) encrypts two fields with AES-256-GCM: NID
numbers (`verification.nid_records.nid_ciphertext`) and admin TOTP secrets
(`identity.admin_credentials.totp_secret_enc`). It also keys the lookup hash that finds
blocked NIDs (`verification.blocked_nids`, `nid_records.nid_hash`) without decrypting.

| Variable | Holds |
|---|---|
| `DATA_ENCRYPTION_KEY` | the current key: new data is encrypted with it |
| `DATA_ENCRYPTION_PREVIOUS_KEYS` | earlier keys, comma-separated, **newest first, the original key last**; data under any of them still decrypts |

Lookup hashes always use the **original** key (the last entry of the list, or the current
key before the first rotation): blocked NIDs are kept only as hashes, so they could
never be re-hashed. Keep the original key in the list for as long as the database
exists; it no longer encrypts anything after step 4 (ADR-0036).

## Planned rotation

1. **Generate the new key** on a trusted machine: `openssl rand -base64 32`. Store it in
   the secret store and in the offline copy next to the old one.
2. **Update the environment** of the API, worker and migrate job (all three identical):
   - `DATA_ENCRYPTION_PREVIOUS_KEYS` = the old `DATA_ENCRYPTION_KEY`, followed by the
     existing list if there is one (`new-old,older,…,original`)
   - `DATA_ENCRYPTION_KEY` = the new key
3. **Deploy** (restart API and worker, `docs/runbooks/deploy.md`). Both refuse to start
   on a malformed entry (`DATA_ENCRYPTION_PREVIOUS_KEYS entries must be 32 bytes,
   base64-encoded`). From now on new data uses the new key and old data still reads.
4. **Re-encrypt** stored fields to the new key:
   ```sh
   /app/migrate reencrypt
   ```
   It runs in one transaction and prints one line per column, e.g.
   `migrate reencrypt: verification.nid_records.nid_ciphertext: 412 rows`. Rows already
   under the current key are skipped, so running it again prints `0 rows`.
5. **Trim the list:** keys between the current and the original one are no longer used.
   Set `DATA_ENCRYPTION_PREVIOUS_KEYS` to the original key alone and deploy again.

## Check

- A verifier opens a provider's NID in the admin console (decrypts with the new key).
- An admin with TOTP signs in.
- A second `/app/migrate reencrypt` prints `0 rows` for both columns.

## Emergency rotation (key leaked)

Run the planned rotation at once, then treat the leaked ciphertext as exposed: anyone
with a database copy taken before step 4 and the old key can read those NID numbers.
Because the original key keys the lookup hashes, a leaked original key also lets an
attacker test guessed NID numbers against `nid_hash` values; record the incident
(`incident-checklist.md`) and ask the owner whether to notify affected providers.

## Rollback

Before step 4, put the old key back as `DATA_ENCRYPTION_KEY` and drop it from the list.
After step 4 keep both keys listed: `DATA_ENCRYPTION_KEY` = the key you return to,
`DATA_ENCRYPTION_PREVIOUS_KEYS` = the other one first, then the original. Never remove
a key while data may still be under it; that data becomes unreadable.
