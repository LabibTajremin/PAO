# Screen inventory

Every screen has a stable **screen ID** (used by RBAC screen permissions and route guards)
that matches the Figma frame name prefix. Build each screen from its Figma frame:
<https://www.figma.com/design/ytbbSEIF1I6cZN0iWJVQsC>. If the Figma tools are available,
use `get_design_context` on the frame; otherwise follow the layout described here and the
`pao_ui` components.

Theme: colours come from the Figma variable collections `Accent` (10 modes, tokens
`tint, soft, primary, strong, deep, on-primary`) and `Base` (neutrals and status). Font:
Plus Jakarta Sans, with Hind Siliguri for Bangla and ৳. Implement these as `pao_ui`
tokens in P10. `on-primary` is `#FFFFFF` in every mode. **Midnight is the default.**

| Mode | tint | soft | primary | strong | deep |
|---|---|---|---|---|---|
| Midnight (default) | `#F3F5FA` | `#E2E7F2` | `#1F3A6E` | `#162B52` | `#0D1B36` |
| Onyx | `#F5F5F6` | `#E6E6E9` | `#1C1C21` | `#0E0E12` | `#0A0A0C` |
| Champagne | `#FBF7EF` | `#F2E8D5` | `#8F6420` | `#6E4C17` | `#2E2108` |
| Merlot | `#FBF2F4` | `#F4E1E7` | `#8A1C3F` | `#69142F` | `#330818` |
| Petrol | `#EFF8F9` | `#D7ECEF` | `#0B5F6B` | `#084852` | `#042A30` |
| Indigo | `#EEF2FF` | `#E0E7FF` | `#4F46E5` | `#3730A3` | `#1E1B4B` |
| Rose | `#FFF1F2` | `#FFE4E6` | `#E11D48` | `#BE123C` | `#4C0519` |
| Tangerine | `#FFF7ED` | `#FFEDD5` | `#EA580C` | `#C2410C` | `#431407` |
| Ocean | `#F0F9FF` | `#E0F2FE` | `#0284C7` | `#075985` | `#082F49` |
| Violet | `#F5F3FF` | `#EDE9FE` | `#7C3AED` | `#5B21B6` | `#2E1065` |

Usage: `primary` = buttons, active tabs, links; `soft` = selected chips, active-tab pill;
`tint` = icon tiles, highlighted cards; `strong` = text on `soft`/`tint`; `deep` = hero
banners and dark headers.

## Customer app (`apps/customer`) — role `customer`

| ID | Screen | Route | PRD |
|---|---|---|---|
| C01 | Splash | `/` | — |
| C02, C31, C32 | Onboarding slides 1–3 + language | `/onboarding` | C-15 |
| C03 | Phone entry | `/auth/phone` | C-01 |
| C04, C33 | OTP (+ wrong-code state) | `/auth/otp` | C-01 |
| C05 | Profile setup | `/auth/profile` | C-01 |
| C06, C34 | Set location (+ permission prompt) | `/auth/location` | C-02 |
| C07, C35 | Home (+ area not covered) | `/home` | C-03 |
| C36 | Offline banner/state | global | §11 |
| C37 | All services | `/services` | C-03 |
| C08, C38 | Search results (+ no results) | `/search` | C-03 |
| C09, C43, C44 | Service detail (on-demand, home salon, driver hire) | `/services/:id` | C-04 |
| C10, C39, C40 | Provider list (+ empty, sort & filter) | `/services/:id/providers` | C-05 |
| C11, C41, C42 | Provider profile (+ badge explainer, all reviews) | `/providers/:id` | C-06 |
| C12, C45, C46 | Booking setup (scheduled, ASAP, choose address) | `/book` | C-07 |
| C13, C13b, C47 | Waiting for provider (+ timed out, declined) | `/bookings/:id/waiting` | C-07, C-10 |
| C48 | Scheduled booking confirmed | `/bookings/:id/confirmed` | C-07 |
| C49, C14, C50, C51 | Booking active: accepted, on the way, arrived, in progress | `/bookings/:id/live` | C-08, C-09 |
| C15 | Extra items approval | `/bookings/:id/extras` | C-09 |
| C52, C53, C54 | Cancel booking (+ cancelled, can't cancel) | `/bookings/:id/cancel` | C-10 |
| C16 | Job completed | `/bookings/:id/completed` | C-08 |
| C17, C55 | Rate provider (+ thanks) | `/bookings/:id/rate` | C-11 |
| C18, C18b, C58 | Bookings: upcoming / past (+ empty) | `/bookings` | C-12 |
| C19, C57 | Booking detail (+ cancelled) | `/bookings/:id` | C-12 |
| C64 | Receipt | `/bookings/:id/receipt` | C-12 |
| C20, C56 | Report a problem (+ submitted) | `/bookings/:id/report` | C-14 |
| C21, C59, C60 | Notifications (+ empty, push payloads) | `/notifications` | C-13 |
| C22 | Account | `/account` | — |
| C23 | Edit profile | `/account/profile` | C-01 |
| C24, C25 | Saved addresses, add/edit address | `/account/addresses` | C-02 |
| C26 | Language | `/account/language` | C-15 |
| C27 | Help & support | `/account/help` | — |
| C28 | Terms & privacy | `/account/legal` | — |
| C29, C61, C62 | Delete account (+ OTP confirm, deleted) | `/account/delete` | §11 |
| C30 | Log out sheet | `/account` | — |
| C63 | Welcome back (session expired) | `/auth/welcome-back` | — |

Not built (D15/D16): C65–C70.

## Partner app (`apps/partner`) — role `provider`

Gate (PRD §8.5): until Level 1, only M01–M14 are reachable; an expired document sends the
provider back to M14 and hides incoming requests.

| ID | Screen | Route | PRD |
|---|---|---|---|
| M01, M02 | Splash, onboarding + language | `/`, `/onboarding` | P-13 |
| M03, M04 | Phone entry, OTP | `/auth/*` | P-01 |
| M05–M13 | Enrolment: personal info, services, service area, NID, selfie, police clearance, skill proof, emergency contact, code of conduct | `/enrol/:step` | P-02 |
| M14 | Verification status + re-upload | `/verification` | P-03 |
| M15, M15b | Home (online / requests paused) | `/home` | P-04, P-11 |
| M16 | Incoming request (countdown, accept/reject with reason) | `/requests/:id` | P-05 |
| M17 | Active job (navigate, call, status actions) | `/jobs/:id/live` | P-06, P-07 |
| M18 | Enter start code | `/jobs/:id/start` | P-06 |
| M19 | Add extra items | `/jobs/:id/extras` | P-06 |
| M20 | Complete job (cash received) | `/jobs/:id/complete` | P-06 |
| M21 | Rate customer | `/jobs/:id/rate` | P-09 |
| M23 | Jobs: upcoming / past | `/jobs` | P-08 |
| M24 | Job detail | `/jobs/:id` | P-08 |
| M25 | Report a problem | `/jobs/:id/report` | — |
| M26, M27 | Earnings summary, earnings by job | `/earnings` | P-08 |
| M28 | Profile | `/profile` | P-10 |
| M29, M30 | Public profile, reviews | `/profile/public`, `/profile/reviews` | P-10 |
| M31 | Documents and expiry | `/profile/documents` | P-11 |
| M32 | Badge & level | `/profile/level` | P-10 |
| M33 | Services & area | `/profile/services` | P-02 |
| M34, M35, M36 | Language, help, log out | `/profile/*` | P-13 |

Also required (not separate Figma frames; reuse patterns from the customer app): request
expired, reject reason sheet, job cancelled by customer, empty jobs/earnings, offline.

## Admin web (`apps/admin`) — roles `verifier`, `catalog_manager`, `support_agent`, `super_admin`

No Figma frames yet. Build with `pao_ui` in a desktop layout (sidebar + content, data
tables, detail drawers), same tokens and accent theme. Screens follow PRD §8.3.

| ID | Screen | Permission | PRD |
|---|---|---|---|
| A01 | Login + 2FA | — | A-01 |
| A02 | Dashboard | `settings:read` or any admin | A-09 |
| A03 | Catalog tree | `catalog:manage` | A-02 |
| A04 | Service editor (BN/EN, icon, model, price, level, radius) | `catalog:manage` | A-02 |
| A05 | Verification queue | `verification:review` | A-03 |
| A06 | Verification review (side-by-side docs, approve/reject per item) | `verification:review` | A-03 |
| A07 | Level 2 session | `level2:manage` | A-04 |
| A08 | Providers list + detail (suspend/ban) | `provider:read` (+ `provider:manage`) | A-05 |
| A09 | Customers list + detail | `customer:read` | A-05 |
| A10 | Bookings monitor + timeline | `booking:read:any` | A-06 |
| A11 | Complaints queue | `complaint:manage` | A-07 |
| A12 | Settings, admin users, roles, audit log | `settings:manage`, `admin_user:manage`, `audit:read` | A-08, A-10 |
