# Domain glossary

Product language used in code, APIs and UI. Feature folders and type names follow it.

| Term | Meaning |
|---|---|
| **Customer** | A registered user with a verified phone who books services. |
| **Provider** | An independent worker enrolled through PAO Partner. Receives bookings only at Level ≥ 1. |
| **Category** | Top-level catalog group, e.g. *Electrical*. |
| **Service** | A trade within a category, e.g. *Electrician*. Has a service model, search radius and required level. |
| **Sub-service** | The bookable item with a fixed, versioned price, e.g. *Ceiling fan installation, ৳X per fan*. |
| **Service model** | How a service books: on-demand job, duration hire, listing or partner referral (PRD §4). |
| **Price version** | An immutable price row. A price change inserts a new version; bookings keep the version they were created with. |
| **Booking** | A customer's request to one chosen provider for one or more sub-services, with snapshots of prices and names. |
| **Snapshot** | Data copied onto a booking at creation so later catalog or profile changes do not alter it. |
| **ASAP / scheduled** | Booking timing: as soon as possible, or a chosen slot. Each has its own accept time limit. |
| **Accept time limit** | How long a provider has to accept or reject a request before it times out. |
| **Start code** | 4-digit code shown only to the customer; the provider enters it to start the job. Cancellation is free until then. |
| **Extra item** | A catalog sub-service the provider adds during the job; the customer must approve it. No free-text prices. |
| **Level** | Verification level: 0 Registered, 1 Document Verified ("Verified"), 2 Skill Verified ("PAO Verified Pro"). |
| **Verification item** | One Level 1 requirement (NID, selfie, police clearance…) with status Pending, Approved, Rejected or Expired. |
| **Level 2 session** | An in-person skill test or supervised job recorded with a per-service checklist. |
| **Presence** | A provider's live online state and location, kept only while online (Redis GEO + heartbeat). |
| **Heartbeat** | The provider app's periodic location ping while online; missing heartbeats take the provider offline. |
| **Provider gate** | Until Level 1 (or after a document expires) the partner app shows only onboarding and verification screens. |
| **Complaint** | A report on a booking from either side, handled in the admin queue. |
| **Outbox** | Per-module table that stores events in the same transaction as the change, relayed to subscribers. |
| **Screen ID** | Stable identifier of an app screen (C01, M14, A05…) used for screen permissions. |
