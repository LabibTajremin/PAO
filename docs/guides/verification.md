# Provider verification: operating procedure

For PAO's verification team. It turns PRD §6 into daily work in the admin console.
No provider can receive a booking without passing verification: providers enter
customers' homes, so when in doubt, reject with a clear reason and let them resubmit.

Permissions: reviewing items needs `verification:review`, opening a document
`verification:docs:view`, Level 2 sessions `level2:manage`, complaints
`complaint:manage`, suspending or banning a provider `provider:manage`, changing the
thresholds below `settings:manage`. Admin roles grant these (Roles screen). Every decision is stored with who, when, what and why,
and cannot be edited (PRD §6.4). Every document view is logged too: open documents only
to review them.

## 1. Levels

| Level | Name | Earned by | Customers see | Can receive bookings |
|---|---|---|---|---|
| 0 | Registered | phone verified by OTP | no badge | no |
| 1 | Document Verified | every required Level 1 item approved | "Verified" | yes |
| 2 | Skill Verified | Level 1 plus a passed Level 2 session | "PAO Verified Pro" | yes, ranked higher |

The level is recalculated by the system after every decision and expiry; nobody sets it
by hand. A service can require Level 2 before the first booking (`requires_level_2` on
the service, Catalog screen; none of the five launch services do, ADR-0016).

A provider receives bookings only when: level ≥ 1 (≥ 2 where the service requires it),
no required document has expired, and the account is not suspended or banned.

## 2. Level 1 review (screen A05 → A06)

The queue lists providers who submitted enrolment, oldest first; filter by service or
by pending item. Aim: every submission reviewed within **2 working days**.

Open a provider and decide **each item** separately: approve, or reject with a reason.
The provider sees the reason in the Partner app and can resubmit that item only.

| # | Item | Approve when | Typical rejection reasons |
|---|---|---|---|
| 1 | Mobile number | automatic (OTP); one account per number | — |
| 2 | NID front and back | number format valid (10, 13 or 17 digits), photo readable, name and date of birth match the profile, NID not on the block list | "photo unreadable", "name does not match profile", "date of birth does not match", "NID expired or damaged" |
| 3 | Live selfie | same person as the NID photo, face fully visible, not a photo of a photo | "face not visible", "does not match NID photo", "selfie is a photo of a screen or print" |
| 4 | Police clearance | genuine certificate, issued in the last 12 months (`verification.police_clearance_validity_days`, 365), name matches | "older than 12 months", "name does not match", "certificate not legible or not genuine" |
| 5 | Present and permanent address | complete and plausible; utility bill if provided matches | "address incomplete", "proof does not match address" |
| 6 | Emergency contact / guarantor | name, relationship and phone; call the number and confirm the person knows the provider | "contact unreachable", "contact does not know the provider" |
| 7 | Skill or trade proof | optional for Level 1; note its quality for Level 2 | "photos do not show the provider's own work" |
| 8 | Service area and categories | the selected services match the proof and experience; home salon providers are women (ADR-0020) | "service not supported by the proof", "service not available to this provider" |
| 9 | Code of conduct | accepted in the app with timestamp and version (automatic) | — |

Rules:

- Write reasons the provider can act on, in plain words; never paste internal notes.
- Signs of fraud (edited NID, someone else's selfie): reject, then open a complaint
  against the provider (section 6) so operations can decide on a ban. A ban puts the
  NID on the block list, so the person cannot register again with it (PRD §6.4).
- Never download, screenshot or forward documents. They are viewed through 5-minute
  signed links only (PRD §6.6).
- Level 1 follows automatically when the last required item is approved; the provider
  is told by push and can go online.

## 3. Level 2 sessions (screen A07)

Level 2 checks the provider's actual work in person (PRD §6.3).

1. **Schedule** a session for one service: interview or skill test at a PAO location, or
   a supervised real job. Enter date, time and place; the provider is notified.
2. **Run** it with the service's checklist (e.g. electrician: safe wiring, tool use,
   earthing awareness). An optional home-address visit is recorded with photos and the
   GPS position.
3. **Record the result** with every checklist line marked and notes:
   - **pass**: the provider becomes Level 2 ("PAO Verified Pro") and ranks higher.
   - **fail**: the provider stays at Level 1 and may book another session after the
     cooling-off period (`verification.level2_cooling_off_days`, default 14 days).
   - **retest**: inconclusive (equipment missing, session cut short); schedule another
     session without a cooling-off period.
4. A recorded result is final; a mistake is corrected by a new session, not an edit.

## 4. Expiry and re-verification

- The police clearance certificate is valid for 12 months from its issue date.
- The provider gets reminders 30, 7 and 1 days before expiry (09:00 Asia/Dhaka).
- At 02:00 Asia/Dhaka on the expiry day the document is marked expired, the level is
  recalculated and the provider **stops receiving bookings automatically** until a new
  certificate is approved. Review renewals first thing in the morning: these providers
  are losing work.
- NID data must be re-checked when the profile changes (PRD §6.4). The system does not
  trigger this yet: when a provider's name or date of birth changes, reject their NID
  item with "profile changed, please resubmit your NID" and review the new submission.

## 5. Ongoing trust: when a level or account changes

Providers are **flagged for review** automatically (ADR-0022; thresholds in Settings):

| Trigger | Default |
|---|---|
| rating below `quality.rating_floor` after `quality.rating_min_jobs` jobs | below 3.5 after 10 jobs |
| provider cancellations after accepting, in 30 days | more than `quality.max_provider_cancellations_30d` (3) |
| a complaint against the provider resolved as **verified** | any |

Every Monday, operations go through the provider list filtered by **flagged** and decide:

- **No action:** note why (e.g. ratings from one disputed customer).
- **Warning:** call the provider; note the call.
- **Re-verification:** reject the affected item(s) with the reason (e.g. new police
  clearance needed); the level drops until they are approved again.
- **Suspend** the account (Pending → Active → **Suspended**): the provider goes offline
  and cannot receive bookings; reversible.
- **Ban**: permanent; the NID, phone and face cannot register again. Use it for fraud,
  violence, theft or harassment confirmed by a verified complaint. A ban needs a second
  admin's agreement, written in the complaint.

## 6. Complaints that affect a level (screen A-07, complaints queue)

Customers and providers report a booking from the app; each report is a complaint.

1. **Assign** it to yourself within one working day.
2. **Investigate:** booking timeline, both parties' accounts, previous complaints; call
   both sides. Write every finding as a comment.
3. **Resolve** with a note and mark it **verified** only when the facts are established
   (not one side's word). A verified complaint counts against the other party and flags
   the provider for review (section 5).
4. **Safety complaints** (theft, violence, harassment) go to the head of operations the
   same day; suspend the provider while it is investigated.

## 7. Account deletion and retention

When a provider deletes their account, their documents are kept for
`documents.retention_days` (365, ADR-0023) after closure and then purged automatically.
Do not delete documents by hand.
