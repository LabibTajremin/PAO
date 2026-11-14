# Database schema

Every table, column, key and index the migrations in `DB Changes/` create, one Postgres
schema per module, in `modules.json` order. It is read from a database migrated with
`migrate up` (the same as [`bundle/schema.sql`](../../DB%20Changes/bundle/schema.sql)); the
"Serves" column says which query each index exists for. Back to [Database](README.md);
[how to find things](#how-to-find-things) is at the end.

The docs gate fails when a table or index of `DB Changes/` is missing here, so a new
migration updates this page in the same change.

## Conventions

- **One schema per module, no cross-module foreign keys** (PRD §9.3 rule 3). Ids of other
  modules (an account id in `booking.bookings.customer_id`, …) are plain `uuid` columns;
  the same person has the same id in `identity.accounts`, `customer.customers` and
  `provider.providers`.
- **Copies, not joins.** A module keeps the fields it needs from another as a read model,
  updated by events (for example `customer.customers.phone`, `rating.reviewable_bookings`).
- **Money** is `bigint` paisa (`*_paisa`); rates are basis points (`*_bp`).
- **Phones** are E.164 (`+8801712345678`); emails are stored as typed and matched on
  `lower(email)`.
- **Time** is `timestamptz` (UTC); "days" for reports are Asia/Dhaka dates.
- **`<module>.outbox`** (every module except audit and notification): events written in
  the same transaction as the change, delivered by the relay at least once, in order per
  `aggregate_id`. Columns: `id`, `aggregate_id`, `event_name`, `payload` (jsonb),
  `created_at`, `published_at`, `attempts`, `next_attempt_at`, `last_error`, `dead`.
  Index `outbox_pending_idx` serves the relay. Published rows are purged after
  `Jobs:OutboxRetentionDays`.
- **`<module>.processed_events`** (every module that consumes events): `(handler,
  event_id)` primary key, so a redelivered event is applied once.
- **`public.goose_<module>`**: the migrator's version table per module (`id`, `version_id`,
  `is_applied`, `tstamp`), in the goose v3 shape; one row per applied script plus the
  version-0 row. `SELECT version_id FROM goose_booking ORDER BY id` shows what ran.
- Extensions: `postgis` (customer, provider, booking locations) and `pg_trgm` (catalog
  search); `public.spatial_ref_sys` belongs to PostGIS.

## `identity`
Tables: [`account_roles`](#identityaccount_roles), [`accounts`](#identityaccounts), [`admin_credentials`](#identityadmin_credentials), [`blocked_phones`](#identityblocked_phones), [`outbox`](#identityoutbox), [`permissions`](#identitypermissions), [`processed_events`](#identityprocessed_events), [`role_permissions`](#identityrole_permissions), [`role_screens`](#identityrole_screens), [`roles`](#identityroles), [`screens`](#identityscreens).

### identity.account_roles
Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `account_id` | uuid | no | — |
| `role` | text | no | — |
| `granted_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (account_id, role)`; FK `FOREIGN KEY (account_id) REFERENCES identity.accounts(id) ON DELETE CASCADE`; FK `FOREIGN KEY (role) REFERENCES identity.roles(name)`.

### identity.accounts
Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `phone` | text | yes | — |
| `email` | text | yes | — |
| `name` | text | no | `''::text` |
| `status` | text | no | `'active'::text` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |
| `deleted_at` | timestamp with time zone | yes | — |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `accounts_email_key` | `(email)` | unique | Unique email (admins only have one). |
| `accounts_email_lower_idx` | `(lower(email)) WHERE (email IS NOT NULL)` | partial | Admin sign-in and `migrate create-admin` by `lower(email)` (IdentityRepository.AdminByEmail); the unique index cannot serve the expression. Added in `identity/0004`. |
| `accounts_phone_key` | `(phone)` | unique | Unique phone; phone sign-in and every lookup of a person by phone (IdentityRepository.AccountByPhone). |

### identity.admin_credentials
Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `account_id` | uuid | no | — |
| `password_hash` | text | no | — |
| `must_change_password` | boolean | no | `true` |
| `totp_secret_enc` | bytea | yes | — |
| `totp_enrolled` | boolean | no | `false` |
| `failed_attempts` | integer | no | `0` |
| `locked_until` | timestamp with time zone | yes | — |
| `active` | boolean | no | `true` |
| `last_login_at` | timestamp with time zone | yes | — |

Keys: PK `PRIMARY KEY (account_id)`; FK `FOREIGN KEY (account_id) REFERENCES identity.accounts(id) ON DELETE CASCADE`.

### identity.blocked_phones
Phones of banned identities cannot sign up again (PRD §6.4). Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `phone` | text | no | — |
| `reason` | text | no | — |
| `blocked_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (phone)`.

### identity.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### identity.permissions
Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `name` | text | no | — |
| `description` | text | no | — |

Keys: PK `PRIMARY KEY (name)`.

### identity.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

### identity.role_permissions
Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `role` | text | no | — |
| `permission` | text | no | — |

Keys: PK `PRIMARY KEY (role, permission)`; FK `FOREIGN KEY (permission) REFERENCES identity.permissions(name) ON DELETE CASCADE`; FK `FOREIGN KEY (role) REFERENCES identity.roles(name) ON DELETE CASCADE`.

### identity.role_screens
Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `role` | text | no | — |
| `screen_id` | text | no | — |

Keys: PK `PRIMARY KEY (role, screen_id)`; FK `FOREIGN KEY (role) REFERENCES identity.roles(name) ON DELETE CASCADE`; FK `FOREIGN KEY (screen_id) REFERENCES identity.screens(id) ON DELETE CASCADE`.

### identity.roles
Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `name` | text | no | — |
| `description` | text | no | — |
| `is_admin` | boolean | no | — |

Keys: PK `PRIMARY KEY (name)`.

### identity.screens
Created in `identity/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | text | no | — |
| `app` | text | no | — |
| `name` | text | no | — |

Keys: PK `PRIMARY KEY (id)`.

## `customer`
Tables: [`addresses`](#customeraddresses), [`customers`](#customercustomers), [`outbox`](#customeroutbox), [`processed_events`](#customerprocessed_events).

### customer.addresses
Created in `customer/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `customer_id` | uuid | no | — |
| `label` | text | no | — |
| `line1` | text | no | — |
| `line2` | text | no | `''::text` |
| `area` | text | no | `''::text` |
| `location` | geography(Point,4326) | no | — |
| `is_default` | boolean | no | `false` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (customer_id) REFERENCES customer.customers(id) ON DELETE CASCADE`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `addresses_customer_idx` | `(customer_id)` | — | A customer's saved addresses (AddressRepository). |
| `addresses_location_gist` | `USING gist (location)` | — | Spatial operations on saved address points (PostGIS). |
| `addresses_one_default` | `(customer_id) WHERE is_default` | unique, partial | Unique partial: at most one default address per customer. |

### customer.customers
Created in `customer/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `name` | text | no | — |
| `photo_media_id` | uuid | yes | — |
| `language` | text | no | `'bn'::text` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |
| `phone` | text | no | `''::text` |
| `account_status` | text | no | `'active'::text` |
| `bookings` | integer | no | `0` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `customers_created_idx` | `(created_at DESC, id DESC)` | — | Admin customer list (A-05), newest first, `(created_at, id)` keyset (CustomerRepository). |

### customer.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `customer/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### customer.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `customer/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

## `provider`
Tables: [`cancellations`](#providercancellations), [`outbox`](#provideroutbox), [`processed_events`](#providerprocessed_events), [`provider_services`](#providerprovider_services), [`providers`](#providerproviders).

### provider.cancellations
Provider cancellations after acceptance, counted over 30 days for the quality review (PRD §6.4, D13). Created in `provider/0002_quality.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `booking_id` | uuid | no | — |
| `provider_id` | uuid | no | — |
| `at` | timestamp with time zone | no | — |

Keys: PK `PRIMARY KEY (booking_id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `cancellations_provider_idx` | `(provider_id, at)` | — | Cancellations after acceptance per merchant over the last 30 days (quality review). |

### provider.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `provider/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### provider.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `provider/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

### provider.provider_services
Created in `provider/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `provider_id` | uuid | no | — |
| `service_id` | uuid | no | — |

Keys: PK `PRIMARY KEY (provider_id, service_id)`; FK `FOREIGN KEY (provider_id) REFERENCES provider.providers(id) ON DELETE CASCADE`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `provider_services_service_idx` | `(service_id)` | — | Merchants offering a service, for nearby search (MerchantRepository); the primary key leads with provider_id. |

### provider.providers
Created in `provider/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `phone` | text | no | `''::text` |
| `full_name` | text | no | `''::text` |
| `date_of_birth` | date | yes | — |
| `gender` | text | yes | — |
| `present_address` | text | no | `''::text` |
| `permanent_address` | text | no | `''::text` |
| `bio` | text | no | `''::text` |
| `photo_media_id` | uuid | yes | — |
| `experience_years` | integer | no | `0` |
| `language` | text | no | `'bn'::text` |
| `home_base` | geography(Point,4326) | yes | — |
| `working_radius_m` | integer | no | `0` |
| `emergency_name` | text | no | `''::text` |
| `emergency_relation` | text | no | `''::text` |
| `emergency_phone` | text | no | `''::text` |
| `emergency_verified_at` | timestamp with time zone | yes | — |
| `coc_version` | text | no | `''::text` |
| `coc_accepted_at` | timestamp with time zone | yes | — |
| `steps_done` | text[] | no | `'{}'::text[]` |
| `submitted_at` | timestamp with time zone | yes | — |
| `account_status` | text | no | `'active'::text` |
| `level` | integer | no | `0` |
| `can_receive_bookings` | boolean | no | `false` |
| `rating_avg` | double precision | no | `0` |
| `rating_count` | integer | no | `0` |
| `completed_jobs` | integer | no | `0` |
| `flagged_for_review` | boolean | no | `false` |
| `flag_reason` | text | no | `''::text` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `providers_home_base_gist` | `USING gist (home_base)` | — | Nearby search: merchants within a radius of the customer (PostGIS distance on home_base). |
| `providers_name_idx` | `(lower(full_name))` | — | Admin merchant list ordered or filtered by `lower(full_name)`. |

## `verification`
Tables: [`blocked_nids`](#verificationblocked_nids), [`closed_accounts`](#verificationclosed_accounts), [`documents`](#verificationdocuments), [`items`](#verificationitems), [`level2_sessions`](#verificationlevel2_sessions), [`levels`](#verificationlevels), [`nid_records`](#verificationnid_records), [`outbox`](#verificationoutbox), [`processed_events`](#verificationprocessed_events), [`reminders_sent`](#verificationreminders_sent).

### verification.blocked_nids
Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `nid_hash` | text | no | — |
| `reason` | text | no | — |
| `blocked_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (nid_hash)`.

### verification.closed_accounts
Accounts closed by their owners: their verification records and documents stay for the retention period (ADR-0023, setting documents.retention_days), then are purged. Created in `verification/0002_closures.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `provider_id` | uuid | no | — |
| `closed_at` | timestamp with time zone | no | — |

Keys: PK `PRIMARY KEY (provider_id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `closed_accounts_closed_idx` | `(closed_at)` | — | Retention sweep of closed accounts, oldest first (ClosedAccountRepository). |

### verification.documents
Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `provider_id` | uuid | no | — |
| `item_type` | text | no | — |
| `kind` | text | no | — |
| `media_id` | uuid | no | — |
| `current` | boolean | no | `true` |
| `created_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `documents_provider_idx` | `(provider_id, item_type) WHERE current` | partial | Partial: the current documents of a merchant per item type (review screen, level computation). |

### verification.items
Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `provider_id` | uuid | no | — |
| `item_type` | text | no | — |
| `status` | text | no | — |
| `rejection_reason` | text | no | `''::text` |
| `fields` | jsonb | no | `'{}'::jsonb` |
| `submitted_at` | timestamp with time zone | yes | — |
| `decided_at` | timestamp with time zone | yes | — |
| `decided_by` | uuid | yes | — |
| `expires_at` | timestamp with time zone | yes | — |

Keys: PK `PRIMARY KEY (provider_id, item_type)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `items_expiry_idx` | `(expires_at) WHERE ((status = 'approved'::text) AND (expires_at IS NOT NULL))` | partial | Partial: approved items that expire, for the expiry sweep and the reminder job. |
| `items_pending_idx` | `(submitted_at) WHERE (status = 'pending'::text)` | partial | Partial: the verifier queue, pending items oldest first (A-03). |

### verification.level2_sessions
Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `provider_id` | uuid | no | — |
| `service_id` | uuid | no | — |
| `scheduled_at` | timestamp with time zone | no | — |
| `location` | text | no | — |
| `status` | text | no | `'scheduled'::text` |
| `result` | text | yes | — |
| `checklist` | jsonb | no | `'[]'::jsonb` |
| `notes` | text | no | `''::text` |
| `visit_lat` | double precision | yes | — |
| `visit_lng` | double precision | yes | — |
| `photo_media_ids` | uuid[] | no | `'{}'::uuid[]` |
| `decided_by` | uuid | yes | — |
| `decided_at` | timestamp with time zone | yes | — |
| `created_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `level2_sessions_provider_idx` | `(provider_id, created_at DESC)` | — | A merchant's Level 2 sessions newest first (last failure, cool-down). |

### verification.levels
Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `provider_id` | uuid | no | — |
| `level` | integer | no | `0` |
| `level2_passed_at` | timestamp with time zone | yes | — |
| `blocked` | boolean | no | `false` |
| `service_ids` | uuid[] | no | `'{}'::uuid[]` |
| `submitted_at` | timestamp with time zone | yes | — |
| `updated_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (provider_id)`.

### verification.nid_records
NID numbers are encrypted (AES-256-GCM); the keyed hash finds blocked identities without decrypting (PRD §6.4, §6.6). Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `provider_id` | uuid | no | — |
| `nid_ciphertext` | bytea | no | — |
| `nid_hash` | text | no | — |
| `updated_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (provider_id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `nid_records_hash_idx` | `(nid_hash)` | — | Duplicate NID detection and blocking by hash (the number itself is encrypted). |

### verification.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### verification.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

### verification.reminders_sent
Created in `verification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `provider_id` | uuid | no | — |
| `item_type` | text | no | — |
| `expires_at` | timestamp with time zone | no | — |
| `days_before` | integer | no | — |
| `sent_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (provider_id, item_type, expires_at, days_before)`.

## `catalog`
Tables: [`banners`](#catalogbanners), [`catalog_version`](#catalogcatalog_version), [`categories`](#catalogcategories), [`outbox`](#catalogoutbox), [`price_versions`](#catalogprice_versions), [`processed_events`](#catalogprocessed_events), [`services`](#catalogservices), [`sub_services`](#catalogsub_services).

### catalog.banners
Created in `catalog/0002_banners.sql`, which also seeds one published demo banner.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `title_en` | text | no | — |
| `title_bn` | text | no | — |
| `subtitle_en` | text | yes | — |
| `subtitle_bn` | text | yes | — |
| `image_url` | text | yes | — |
| `service_id` | uuid | yes | — |
| `sort_order` | integer | no | `0` |
| `published` | boolean | no | `false` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (service_id) REFERENCES catalog.services(id)`. Checks: both subtitles or neither; `image_url` starts with `https://`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `banners_published_idx` | `(sort_order) WHERE published` | partial | The customer home's published banners in display order (BannerRepository.List). |

### catalog.catalog_version
Created in `catalog/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `singleton` | boolean | no | `true` |
| `version` | bigint | no | `1` |

Keys: PK `PRIMARY KEY (singleton)`.

### catalog.categories
Created in `catalog/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `name_en` | text | no | — |
| `name_bn` | text | no | — |
| `icon_key` | text | no | — |
| `sort_order` | integer | no | `0` |
| `published` | boolean | no | `false` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`.

### catalog.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `catalog/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### catalog.price_versions
Every price change inserts a row; rows are never updated so booked prices stay reproducible (PRD §4). Created in `catalog/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `sub_service_id` | uuid | no | — |
| `amount_paisa` | bigint | no | — |
| `effective_from` | timestamp with time zone | no | `now()` |
| `created_by` | uuid | no | — |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (sub_service_id) REFERENCES catalog.sub_services(id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `price_versions_sub_service_idx` | `(sub_service_id, effective_from DESC)` | — | Price history of a sub-service newest first (CatalogRepository.PriceHistory). |

### catalog.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `catalog/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

### catalog.services
Created in `catalog/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `category_id` | uuid | no | — |
| `name_en` | text | no | — |
| `name_bn` | text | no | — |
| `icon_key` | text | no | — |
| `service_model` | text | no | — |
| `required_level` | integer | no | `1` |
| `search_radius_m` | integer | no | `5000` |
| `women_providers_only` | boolean | no | `false` |
| `requires_level_2` | boolean | no | `false` |
| `level2_checklist` | jsonb | no | `'[]'::jsonb` |
| `sort_order` | integer | no | `0` |
| `published` | boolean | no | `false` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (category_id) REFERENCES catalog.categories(id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `services_category_idx` | `(category_id)` | — | Services of a category when the tree is built; also backs the foreign key. |
| `services_search_trgm` | `USING gin (lower(((name_en \|\| ' '::text) \|\| name_bn)) gin_trgm_ops)` | — | Service search: `LIKE '%term%'` and `word_similarity` on the lower-cased names (pg_trgm). |

### catalog.sub_services
Created in `catalog/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `service_id` | uuid | no | — |
| `name_en` | text | no | — |
| `name_bn` | text | no | — |
| `description` | jsonb | no | `'{"bn": "", "en": ""}'::jsonb` |
| `inclusions` | jsonb | no | `'[]'::jsonb` |
| `exclusions` | jsonb | no | `'[]'::jsonb` |
| `unit` | text | no | — |
| `max_quantity` | integer | no | `10` |
| `sort_order` | integer | no | `0` |
| `published` | boolean | no | `false` |
| `current_price_version_id` | uuid | yes | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |
| `search_text` | text | yes | `generated` |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (current_price_version_id) REFERENCES catalog.price_versions(id)`; FK `FOREIGN KEY (service_id) REFERENCES catalog.services(id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `sub_services_search_trgm` | `USING gin (search_text gin_trgm_ops)` | — | Sub-service search on the generated `search_text` (pg_trgm). |
| `sub_services_service_idx` | `(service_id)` | — | Sub-services of a service when the tree is built; also backs the foreign key. |

## `booking`
Tables: [`booking_items`](#bookingbooking_items), [`bookings`](#bookingbookings), [`extras_proposals`](#bookingextras_proposals), [`outbox`](#bookingoutbox), [`processed_events`](#bookingprocessed_events), [`timeline`](#bookingtimeline).

### booking.booking_items
Created in `booking/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `booking_id` | uuid | no | — |
| `proposal_id` | uuid | yes | — |
| `sub_service_id` | uuid | no | — |
| `price_version_id` | uuid | no | — |
| `name_en` | text | no | — |
| `name_bn` | text | no | — |
| `unit` | text | no | — |
| `quantity` | integer | no | — |
| `unit_price_paisa` | bigint | no | — |
| `total_paisa` | bigint | no | — |
| `extra` | boolean | no | `false` |
| `position` | integer | no | — |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (booking_id) REFERENCES booking.bookings(id) ON DELETE CASCADE`; FK `FOREIGN KEY (proposal_id) REFERENCES booking.extras_proposals(id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `booking_items_booking_idx` | `(booking_id, "position")` | — | Lines of a booking in position order (BookingQueries.Get). |

### booking.bookings
Created in `booking/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `number` | bigint | no | `nextval('booking.booking_number_seq'::regclass)` |
| `customer_id` | uuid | no | — |
| `provider_id` | uuid | no | — |
| `service_id` | uuid | no | — |
| `service_name_en` | text | no | — |
| `service_name_bn` | text | no | — |
| `service_model` | text | no | — |
| `customer_name` | text | no | — |
| `customer_phone` | text | no | — |
| `provider_name` | text | no | — |
| `provider_phone` | text | no | — |
| `address_id` | uuid | no | — |
| `address_area` | text | no | — |
| `address_line1` | text | no | — |
| `address_line2` | text | no | `''::text` |
| `address_location` | geography(Point,4326) | no | — |
| `note` | text | no | `''::text` |
| `status` | text | no | — |
| `timing` | text | no | — |
| `scheduled_at` | timestamp with time zone | yes | — |
| `ends_at` | timestamp with time zone | yes | — |
| `accept_deadline` | timestamp with time zone | no | — |
| `total_paisa` | bigint | no | — |
| `start_code` | text | no | — |
| `start_code_attempts` | integer | no | `0` |
| `start_code_locked_until` | timestamp with time zone | yes | — |
| `cash_received` | boolean | no | `false` |
| `idempotency_key` | text | no | — |
| `cancel_reason` | text | no | `''::text` |
| `cancelled_by` | text | yes | — |
| `reject_reason` | text | no | `''::text` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |
| `accepted_at` | timestamp with time zone | yes | — |
| `started_at` | timestamp with time zone | yes | — |
| `completed_at` | timestamp with time zone | yes | — |
| `cancelled_at` | timestamp with time zone | yes | — |
| `payment_method` | text | no | `'cash_on_delivery'::text` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `bookings_accept_due_idx` | `(accept_deadline) WHERE (status = 'requested'::text)` | partial | Partial: requests whose accept deadline passed, oldest first, for BookingExpiryJob every 15 s (BookingQueries.Due). Added in `booking/0003`. |
| `bookings_active_job_idx` | `(provider_id) WHERE (status = ANY (ARRAY['accepted'::text, 'on_the_way'::text, 'arrived'::text, 'in_progress'::text]))` | partial | Partial: a merchant's job in progress (accepted … in_progress), to keep one active job and find busy merchants. |
| `bookings_created_idx` | `(created_at DESC, id DESC)` | — | Admin booking monitor without a status filter, newest first keyset (BookingQueries.Monitor, A-06). Added in `booking/0003`. |
| `bookings_customer_id_idempotency_key_key` | `(customer_id, idempotency_key)` | unique | Unique: an `Idempotency-Key` replay returns the booking already created. |
| `bookings_customer_idx` | `(customer_id, created_at DESC, id DESC)` | — | A customer's bookings newest first, `(created_at, id)` keyset (BookingQueries.List). |
| `bookings_number_key` | `(number)` | unique | Unique human-readable booking number; lookup by number. |
| `bookings_one_request_per_pair` | `(customer_id, provider_id) WHERE (status = 'requested'::text)` | unique, partial | Unique partial: one open request per customer and merchant. |
| `bookings_provider_idx` | `(provider_id, created_at DESC, id DESC)` | — | A merchant's bookings newest first and earnings per day (BookingQueries.List, EarningsByDay). |
| `bookings_status_idx` | `(status, created_at DESC)` | — | Admin monitor filtered by status, newest first; status counts. |

### booking.extras_proposals
Created in `booking/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `booking_id` | uuid | no | — |
| `status` | text | no | — |
| `added_paisa` | bigint | no | — |
| `proposed_at` | timestamp with time zone | no | `now()` |
| `decided_at` | timestamp with time zone | yes | — |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (booking_id) REFERENCES booking.bookings(id) ON DELETE CASCADE`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `extras_one_pending` | `(booking_id) WHERE (status = 'pending'::text)` | unique, partial | Unique partial: at most one pending extras proposal per booking. |
| `extras_proposals_booking_idx` | `(booking_id, proposed_at)` | — | Proposals of a booking in order, read on every booking read and state change (BookingQueries.Get, BookingRepository.Change). Added in `booking/0003`. |

### booking.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `booking/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### booking.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `booking/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

### booking.timeline
Created in `booking/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `booking_id` | uuid | no | — |
| `status` | text | no | — |
| `actor` | text | no | — |
| `reason` | text | no | `''::text` |
| `at` | timestamp with time zone | no | — |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (booking_id) REFERENCES booking.bookings(id) ON DELETE CASCADE`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `timeline_booking_idx` | `(booking_id, at)` | — | Timeline of a booking in order. |

## `rating`
Tables: [`aggregates`](#ratingaggregates), [`outbox`](#ratingoutbox), [`processed_events`](#ratingprocessed_events), [`reviewable_bookings`](#ratingreviewable_bookings), [`reviews`](#ratingreviews).

### rating.aggregates
Created in `rating/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `subject_id` | uuid | no | — |
| `subject_role` | text | no | — |
| `review_count` | integer | no | `0` |
| `star_sum` | bigint | no | `0` |
| `stars_1` | integer | no | `0` |
| `stars_2` | integer | no | `0` |
| `stars_3` | integer | no | `0` |
| `stars_4` | integer | no | `0` |
| `stars_5` | integer | no | `0` |

Keys: PK `PRIMARY KEY (subject_id, subject_role)`.

### rating.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `rating/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### rating.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `rating/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

### rating.reviewable_bookings
Completed bookings copied from BookingCompleted events: the only bookings that may be reviewed, once per side. Created in `rating/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `booking_id` | uuid | no | — |
| `customer_id` | uuid | no | — |
| `provider_id` | uuid | no | — |
| `customer_name` | text | no | — |
| `provider_name` | text | no | — |
| `service_name_en` | text | no | — |
| `service_name_bn` | text | no | — |
| `completed_at` | timestamp with time zone | no | — |

Keys: PK `PRIMARY KEY (booking_id)`.

### rating.reviews
Created in `rating/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `booking_id` | uuid | no | — |
| `author_id` | uuid | no | — |
| `author_role` | text | no | — |
| `author_name` | text | no | — |
| `subject_id` | uuid | no | — |
| `stars` | integer | no | — |
| `tags` | text[] | no | `'{}'::text[]` |
| `comment` | text | no | `''::text` |
| `service_name_en` | text | no | — |
| `service_name_bn` | text | no | — |
| `created_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `reviews_booking_id_author_role_key` | `(booking_id, author_role)` | unique | Unique: one review per booking and side (customer, merchant). |
| `reviews_subject_idx` | `(subject_id, created_at DESC, id DESC)` | — | Reviews of a person newest first, keyset (RatingRepository). |

## `notification`
Tables: [`device_tokens`](#notificationdevice_tokens), [`notifications`](#notificationnotifications), [`processed_events`](#notificationprocessed_events), [`recipients`](#notificationrecipients).

### notification.device_tokens
Created in `notification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `token` | text | no | — |
| `account_id` | uuid | no | — |
| `app` | text | no | — |
| `platform` | text | no | — |
| `updated_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (token)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `device_tokens_account_idx` | `(account_id, app)` | — | Push tokens of an account for one app. |

### notification.notifications
Created in `notification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `recipient_id` | uuid | no | — |
| `app` | text | no | — |
| `type` | text | no | — |
| `title` | text | no | — |
| `body` | text | no | — |
| `booking_id` | uuid | yes | — |
| `dedupe_key` | text | no | — |
| `read_at` | timestamp with time zone | yes | — |
| `created_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `notifications_inbox_idx` | `(recipient_id, app, created_at DESC, id DESC)` | — | Inbox of a recipient in one app newest first, keyset (NotificationRepository). |
| `notifications_recipient_id_dedupe_key_key` | `(recipient_id, dedupe_key)` | unique | Unique: `ON CONFLICT (recipient_id, dedupe_key) DO NOTHING` makes event redelivery harmless. |
| `notifications_unread_idx` | `(recipient_id, app) WHERE (read_at IS NULL)` | partial | Partial: unread count and mark-all-read. |

### notification.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `notification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

### notification.recipients
Recipient language, copied from profile events, so templates render without calls. Created in `notification/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `account_id` | uuid | no | — |
| `language` | text | no | `'bn'::text` |

Keys: PK `PRIMARY KEY (account_id)`.

## `media`
Tables: [`objects`](#mediaobjects), [`outbox`](#mediaoutbox), [`processed_events`](#mediaprocessed_events).

### media.objects
Created in `media/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `owner_id` | uuid | no | — |
| `purpose` | text | no | — |
| `content_type` | text | no | — |
| `size_bytes` | bigint | no | — |
| `bucket` | text | no | — |
| `object_key` | text | no | — |
| `status` | text | no | `'pending'::text` |
| `attached` | boolean | no | `false` |
| `created_at` | timestamp with time zone | no | `now()` |
| `confirmed_at` | timestamp with time zone | yes | — |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `objects_object_key_key` | `(object_key)` | unique | Unique storage key of an object. |
| `objects_orphan_idx` | `(created_at) WHERE (NOT attached)` | partial | Partial: orphan sweep, unattached uploads oldest first (MediaRepository). |
| `objects_owner_idx` | `(owner_id)` | — | Uploads of an owner (listing, account erase). |

### media.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `media/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### media.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `media/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

## `admin`
Tables: [`complaint_comments`](#admincomplaint_comments), [`complaints`](#admincomplaints), [`outbox`](#adminoutbox), [`processed_events`](#adminprocessed_events), [`settings`](#adminsettings), [`stats_bookings_daily`](#adminstats_bookings_daily), [`stats_providers`](#adminstats_providers).

### admin.complaint_comments
Created in `admin/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `complaint_id` | uuid | no | — |
| `author_id` | uuid | no | — |
| `body` | text | no | — |
| `at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`; FK `FOREIGN KEY (complaint_id) REFERENCES admin.complaints(id) ON DELETE CASCADE`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `complaint_comments_idx` | `(complaint_id, at)` | — | Comments of a complaint in order. |

### admin.complaints
Created in `admin/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `ticket_number` | bigint | no | `nextval('admin.ticket_number_seq'::regclass)` |
| `booking_id` | uuid | no | — |
| `reporter_id` | uuid | no | — |
| `reporter_role` | text | no | — |
| `against_id` | uuid | no | — |
| `reason` | text | no | — |
| `description` | text | no | — |
| `photo_media_ids` | uuid[] | no | `'{}'::uuid[]` |
| `status` | text | no | `'open'::text` |
| `assignee_id` | uuid | yes | — |
| `resolution` | text | no | `''::text` |
| `verified` | boolean | no | `false` |
| `created_at` | timestamp with time zone | no | `now()` |
| `updated_at` | timestamp with time zone | no | `now()` |
| `resolved_at` | timestamp with time zone | yes | — |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `complaints_against_all_idx` | `(against_id, created_at DESC, id DESC)` | — | Every complaint against a person and the newest involving them (ComplaintRepository.CountAgainst, Involving; AdminConsole). Added in `admin/0003`. |
| `complaints_against_idx` | `(against_id) WHERE verified` | partial | Partial: verified complaints against a person (ComplaintRepository.CountVerified, PRD §6.4). |
| `complaints_queue_idx` | `(status, created_at DESC, id DESC)` | — | Admin complaint queue by status, newest first, keyset (A-07). |
| `complaints_reporter_idx` | `(reporter_id)` | — | Complaints a person filed (Involving, together with the against index). |
| `complaints_ticket_number_key` | `(ticket_number)` | unique | Unique ticket number; lookup by ticket. |

### admin.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `admin/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### admin.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `admin/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

### admin.settings
Created in `admin/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `key` | text | no | — |
| `value` | text | no | — |
| `type` | text | no | — |
| `description` | text | no | — |
| `updated_at` | timestamp with time zone | no | `now()` |
| `updated_by` | uuid | yes | — |

Keys: PK `PRIMARY KEY (key)`.

### admin.stats_bookings_daily
Dashboard read model, fed by booking, verification and identity events (A-09). Created in `admin/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `day` | date | no | — |
| `requested` | integer | no | `0` |
| `completed` | integer | no | `0` |

Keys: PK `PRIMARY KEY (day)`.

### admin.stats_providers
Created in `admin/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `provider_id` | uuid | no | — |
| `status` | text | no | `'pending'::text` |
| `level` | integer | no | `0` |

Keys: PK `PRIMARY KEY (provider_id)`.

## `audit`
Tables: [`entries`](#auditentries), [`processed_events`](#auditprocessed_events).

### audit.entries
Created in `audit/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `at` | timestamp with time zone | no | `now()` |
| `actor_id` | uuid | yes | — |
| `actor_role` | text | no | `''::text` |
| `action` | text | no | — |
| `subject_type` | text | no | — |
| `subject_id` | text | no | — |
| `reason` | text | no | `''::text` |
| `before` | jsonb | yes | — |
| `after` | jsonb | yes | — |
| `event_id` | uuid | yes | — |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `entries_action_idx` | `(action, at DESC)` | — | Audit trail filtered by action, newest first (A-08). |
| `entries_actor_idx` | `(actor_id, at DESC)` | — | Audit trail filtered by actor, newest first. |
| `entries_at_idx` | `(at DESC, id DESC)` | — | The whole trail newest first, `(at, id)` keyset (AuditRepository.List). |
| `entries_event_id_key` | `(event_id)` | unique | Unique: an event is recorded once (`ON CONFLICT (event_id) DO NOTHING`). |
| `entries_subject_idx` | `(subject_type, subject_id, at DESC)` | — | History of one subject (type and id), newest first. |

### audit.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `audit/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

## `billing`
Tables: [`ledger_entries`](#billingledger_entries), [`outbox`](#billingoutbox), [`payment_submissions`](#billingpayment_submissions), [`processed_events`](#billingprocessed_events).

### billing.ledger_entries
A commission is a debit, a confirmed payment a credit. Amounts are positive; the kind gives the sign. One commission per booking makes a redelivered completion harmless. Created in `billing/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `provider_id` | uuid | no | — |
| `kind` | text | no | — |
| `amount_paisa` | bigint | no | — |
| `booking_id` | uuid | yes | — |
| `booking_number` | bigint | yes | — |
| `job_total_paisa` | bigint | yes | — |
| `rate_bp` | integer | yes | — |
| `submission_id` | uuid | yes | — |
| `created_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `ledger_entries_booking_kind_key` | `(booking_id, kind)` | unique | Unique: one commission (or other kind) per booking, so a redelivered completion posts once. |
| `ledger_entries_provider_idx` | `(provider_id, created_at DESC, id DESC)` | — | A merchant's ledger newest first and their balance (BillingRepository). |
| `ledger_entries_submission_id_key` | `(submission_id)` | unique | Unique: one ledger entry per confirmed payment submission. |

### billing.outbox
Events written in the same transaction as the change; the relay delivers them at least once, in order per aggregate (PRD §9.3 rule 5). Created in `billing/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `aggregate_id` | text | no | — |
| `event_name` | text | no | — |
| `payload` | jsonb | no | — |
| `created_at` | timestamp with time zone | no | `now()` |
| `published_at` | timestamp with time zone | yes | — |
| `attempts` | integer | no | `0` |
| `next_attempt_at` | timestamp with time zone | no | `now()` |
| `last_error` | text | yes | — |
| `dead` | boolean | no | `false` |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `outbox_pending_idx` | `(next_attempt_at, created_at) WHERE ((published_at IS NULL) AND (NOT dead))` | partial | Outbox relay: pending, not dead events oldest first (`FOR UPDATE SKIP LOCKED`, OutboxRelay); partial, so delivered rows cost nothing. |

### billing.payment_submissions
Created in `billing/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `id` | uuid | no | — |
| `provider_id` | uuid | no | — |
| `amount_paisa` | bigint | no | — |
| `method` | text | no | — |
| `reference` | text | no | — |
| `status` | text | no | `'pending'::text` |
| `reviewer_id` | uuid | yes | — |
| `reason` | text | no | `''::text` |
| `created_at` | timestamp with time zone | no | `now()` |
| `reviewed_at` | timestamp with time zone | yes | — |

Keys: PK `PRIMARY KEY (id)`.

| Index | Columns | Kind | Serves |
|---|---|---|---|
| `payment_submissions_provider_idx` | `(provider_id, created_at DESC, id DESC)` | — | A merchant's payment submissions newest first; pending count. |
| `payment_submissions_queue_idx` | `(status, created_at DESC, id DESC)` | — | Admin payment review queue by status, newest first (ADR-0035 §4). |

### billing.processed_events
Handlers record events they have applied so redelivery is harmless. Created in `billing/0001_init.sql`.

| Column | Type | Null | Default |
|---|---|---|---|
| `handler` | text | no | — |
| `event_id` | uuid | no | — |
| `processed_at` | timestamp with time zone | no | `now()` |

Keys: PK `PRIMARY KEY (handler, event_id)`.

## Index review

Checked against the repository queries (`PAO.Core/Areas/*/Repositories`, the jobs and the
outbox). Added where a hot or growing lookup had no supporting index:

| Script | Index | Why |
|---|---|---|
| `identity/0004_admin_email_index.sql` | `accounts_email_lower_idx` | admin sign-in matched `lower(email)` with a full scan of every account |
| `booking/0003_lookup_indexes.sql` | `bookings_accept_due_idx` | the 15-second expiry sweep orders open requests by deadline |
| `booking/0003_lookup_indexes.sql` | `bookings_created_idx` | the admin monitor pages all bookings newest first |
| `booking/0003_lookup_indexes.sql` | `extras_proposals_booking_idx` | proposals are read by booking on every booking read and change; only the pending one was indexed |
| `admin/0003_complaints_against_index.sql` | `complaints_against_all_idx` | the admin person view counts and lists all complaints against a person; only verified ones were indexed |

Left as they are on purpose: the outbox purge (`DELETE … WHERE published_at < …`, daily at 03:00 over a table kept small by that purge), reviews by `author_id` and bookings by
`customer_id OR provider_id` on account erase (rare, and the second is covered by the two
party indexes), the admin text searches `LIKE '%term%'` on names and phones (small admin
lists ordered by an indexed key), and audit filtered by subject id without its type
(`entries_subject_idx` leads with the type; filter on both).

## How to find things

Run these in a SQL editor (Neon) or `psql`; replace the literals. Phones are E.164.

| To find | Query | Index used |
|---|---|---|
| A person by phone | `SELECT * FROM identity.accounts WHERE phone = '+8801712345678';` | `accounts_phone_key` |
| Their roles | `SELECT role FROM identity.account_roles WHERE account_id = '<id>';` | primary key |
| An admin by email | `SELECT * FROM identity.accounts WHERE lower(email) = lower('owner@pao.com.bd');` | `accounts_email_lower_idx` |
| Whether a phone is banned | `SELECT * FROM identity.blocked_phones WHERE phone = '+8801712345678';` | primary key |
| A customer's profile and addresses | `SELECT * FROM customer.customers WHERE id = '<account id>';` then `SELECT * FROM customer.addresses WHERE customer_id = '<account id>';` | primary key, `addresses_customer_idx` |
| A merchant (provider) and level | `SELECT * FROM provider.providers WHERE id = '<account id>';` and `SELECT * FROM verification.levels WHERE provider_id = '<account id>';` | primary keys |
| A merchant by phone | `SELECT id, full_name, level, account_status FROM provider.providers WHERE phone = '+8801712345678';` (or find the account id in `identity.accounts` first) | scan of a small table; the account lookup uses `accounts_phone_key` |
| A merchant's verification items | `SELECT * FROM verification.items WHERE provider_id = '<id>';` | primary key |
| The verifier queue | `SELECT * FROM verification.items WHERE status = 'pending' ORDER BY submitted_at;` | `items_pending_idx` |
| A booking by id or number | `SELECT * FROM booking.bookings WHERE id = '<id>';` / `WHERE number = '<number>';` | primary key / `bookings_number_key` |
| Its lines, proposals and timeline | `SELECT * FROM booking.booking_items WHERE booking_id = '<id>' ORDER BY position;` (likewise `booking.extras_proposals … ORDER BY proposed_at`, `booking.timeline … ORDER BY at`) | `booking_items_booking_idx`, `extras_proposals_booking_idx`, `timeline_booking_idx` |
| A customer's bookings | `SELECT * FROM booking.bookings WHERE customer_id = '<id>' ORDER BY created_at DESC, id DESC LIMIT 20;` | `bookings_customer_idx` |
| A merchant's bookings | `SELECT * FROM booking.bookings WHERE provider_id = '<id>' ORDER BY created_at DESC, id DESC LIMIT 20;` | `bookings_provider_idx` |
| A merchant's active job | `SELECT * FROM booking.bookings WHERE provider_id = '<id>' AND status IN ('accepted', 'on_the_way', 'arrived', 'in_progress');` | `bookings_active_job_idx` |
| A merchant's ledger | `SELECT * FROM billing.ledger_entries WHERE provider_id = '<id>' ORDER BY created_at DESC, id DESC;` | `ledger_entries_provider_idx` |
| A merchant's dues | `SELECT sum(amount_paisa) FILTER (WHERE kind = 'commission') - coalesce(sum(amount_paisa) FILTER (WHERE kind = 'payment'), 0) AS due_paisa FROM billing.ledger_entries WHERE provider_id = '<id>';` | `ledger_entries_provider_idx` |
| The commission of a booking | `SELECT * FROM billing.ledger_entries WHERE booking_id = '<id>' AND kind = 'commission';` | `ledger_entries_booking_kind_key` |
| Payments waiting for review | `SELECT * FROM billing.payment_submissions WHERE status = 'pending' ORDER BY created_at DESC;` | `payment_submissions_queue_idx` |
| Reviews of a person and their average | `SELECT * FROM rating.reviews WHERE subject_id = '<id>' ORDER BY created_at DESC;` and `SELECT star_sum::numeric / nullif(review_count, 0) FROM rating.aggregates WHERE subject_id = '<id>';` | `reviews_subject_idx`, primary key |
| A complaint by ticket | `SELECT * FROM admin.complaints WHERE ticket_number = '<ticket>';` | `complaints_ticket_number_key` |
| Complaints against a person | `SELECT * FROM admin.complaints WHERE against_id = '<id>' ORDER BY created_at DESC;` | `complaints_against_all_idx` |
| Someone's notifications | `SELECT * FROM notification.notifications WHERE recipient_id = '<id>' AND app = 'customer' ORDER BY created_at DESC, id DESC;` | `notifications_inbox_idx` |
| Their push tokens | `SELECT * FROM notification.device_tokens WHERE account_id = '<id>';` | `device_tokens_account_idx` |
| An uploaded file | `SELECT * FROM media.objects WHERE id = '<media id>';` (`object_key` is the storage key) | primary key |
| What happened to something | `SELECT * FROM audit.entries WHERE subject_type = 'booking' AND subject_id = '<id>' ORDER BY at DESC;` | `entries_subject_idx` |
| What an admin did | `SELECT * FROM audit.entries WHERE actor_id = '<id>' ORDER BY at DESC;` | `entries_actor_idx` |
| The catalog | `SELECT c.name_en, s.name_en, ss.name_en, p.amount_paisa FROM catalog.categories c JOIN catalog.services s ON s.category_id = c.id JOIN catalog.sub_services ss ON ss.service_id = s.id LEFT JOIN catalog.price_versions p ON p.id = ss.current_price_version_id ORDER BY c.sort_order, s.sort_order, ss.sort_order;` | `services_category_idx`, `sub_services_service_idx` |
| A platform setting | `SELECT * FROM admin.settings WHERE key = 'billing.commission_rate_bp';` | primary key |
| Events stuck in an outbox | `SELECT * FROM booking.outbox WHERE published_at IS NULL ORDER BY created_at;` (any module) | `outbox_pending_idx` |
| Which migrations ran | `SELECT version_id, tstamp FROM goose_booking ORDER BY id;` (any module) | — |
