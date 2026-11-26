# Verification area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request and handler. Business rules the schema cannot express are domain errors raised by the
services. Overview: [overview.md](overview.md).

| Feature | Requests | What it does |
|---|---|---|
| `Enrolment` | `SaveNid`, `SaveSelfie`, `SavePoliceClearance`, `SaveSkillProof`, `SubmitEnrolment` | Document steps M08–M11: checks each upload (owner, confirmed, purpose), puts the item into review, marks the wizard step through the Merchant contract. The NID is stored AES-GCM encrypted with a keyed lookup hash; a blocked NID answers `NID_BLOCKED`. The police clearance issue date is compared with the Dhaka date. |
| `Status` | `GetVerificationStatus` | The merchant's own screen: items, level, badge, Level 2 eligibility, cooling-off and next session. |
| `Review` | `ListVerificationQueue`, `GetVerificationReview`, `DecideVerificationItem` | The queue (oldest first, keyset paged), the review screen (NID decrypted only here) and approve / reject. A rejection with a reason is how a verifier requests changes: the item goes back to the merchant. |
| `Level2` | `ScheduleLevel2Session`, `RecordLevel2Result`, `ListLevel2Sessions`, `GetLevel2Session` | Level 2 sessions (PRD §6.3): Level 1 only, no booking during cooling-off, a pass raises the level to 2. |
| `Maintenance` | `ExpireDocuments`, `RemindExpiringDocuments`, `PurgeClosedAccounts` | The jobs' use cases: expiry sweep, 30/7/1 day reminders sent once each, and the closed-account purge after the retention period (ADR-0023). |
| `Events` | `ApplyStepSaved`, `ApplyAccountStatus`, `RecordAccountClosure` | Reactions to `provider.EnrolmentStepSaved`, `identity.AccountStatusChanged` and `identity.AccountDeleted`. |

Every change runs under the merchant's `levels` row lock and recomputes the level, publishing
`ProviderLevelChanged` in the same transaction.
