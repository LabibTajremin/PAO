# P24 — Illustrations, welcome and sign-in pages

**Goal:** the customer and partner apps open with warm, Bangladeshi illustrations in the
palette, and the sign-in screens follow the owner's demo.

**Read first:** `06-update-2026-11.md` §5 (sizes, style, motifs), items viii, xv, xvii;
`design/reference/sign-in-illustration-demo.jpg`; customer `onboarding/`, `auth/`; partner
`onboarding/`, `auth/`.

## Tasks

1. **Draw the illustrations** as hand-authored SVG in `design/illustrations/`, one file per slot
   in §5, at the slot's size and ratio, following the style rules. Suggested scenes:
   - `customer.signin.hero`: two neighbours on a Dhaka rooftop checking the PAO app, water tank,
     potted plants, a cat, service bubbles (tools, home, car, bazar bag) around them, skyline
     with Sangsad Bhaban silhouette.
   - `customer.onboarding.1–3`: find (a lane of shops and a rickshaw); book (a family at a tea
     table choosing a time); done (an electrician waving from a doorway with kantha-pattern curtain).
   - `partner.signin.hero`: a technician with tool bag beside a rickshaw van, phone in hand.
   - `partner.onboarding.1–3`: get requests; earn and grow (a tiffin carrier and a bazar bag for
     food partners); verified badge pride.
   - Empty, offline, success and admin login slots: small scenes with one object each (an empty
     jute bag, a resting cat, a tea cup, a paper boat for offline, a garland for success).
   Self-review every file at full size and at phone size before committing; no text inside.
2. **Sign-in (both apps)**, per the demo minus the Google section: illustration in the top ~55%,
   PAO wordmark (inverse on the hero) and the tagline over it, a rounded `card` sheet with
   "Welcome to PAO", one line of subtitle, phone field with the +880 prefix, one primary "Send
   OTP" button and the terms line. **No social sign-in, no "or continue with".**
3. **Welcome / onboarding:** three slides per app with the illustrations, title + one line, dots,
   Skip and Next; language chooser kept.
4. **Empty, offline and success states** use their slots through `PaoArtwork`.
5. **Tests:** widget tests for each page state; goldens light/dark × en/bn; accessibility labels on
   every illustration (`semanticLabel`) or excluded when decorative.

## Definition of done

Both apps' first-run, sign-in, empty and success screens use the new illustrations, look right
on a 360 dp Android and a 393 pt iPhone in both modes. `./pao ci` green.
