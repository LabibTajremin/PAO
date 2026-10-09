# P05 — Customer

**Goal:** customer profiles and saved addresses with map pins.

**Read first:** PRD features C-01, C-02, §11 (privacy); screens C05, C06, C22–C25.

## Tasks

1. **Domain** — `Customer` (name, optional photo media ID, language `en|bn`), `Address`
   (label home/office/other, free-text lines, `geography` point, default flag, max 10
   per customer).
2. **Use cases** — create/update profile, add/edit/delete/set-default address,
   `GetCustomer` and `GetAddress` contracts (address returned to a provider only through
   booking after acceptance — PRD §11), service-area check (is the point inside an active
   launch area polygon from settings? used by screen C35).
3. **Account deletion** — subscribe to `AccountDeleted`: erase profile and addresses.
4. **HTTP** — `/v1/customer/profile`, `/v1/customer/addresses*`.

## Tests

- Unit: address limits, default-address switching, coordinate validation (inside
  Bangladesh bounds).
- Integration: repository incl. PostGIS round-trip, ownership (customer A cannot read B's
  address → 404), deletion subscriber.

## Definition of done

`./pao ci` green; PR merged.
