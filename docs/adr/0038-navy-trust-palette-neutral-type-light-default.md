# ADR-0038: Navy trust palette, neutral type and light by default

- Status: Accepted
- Date: 2026-11-21
- Source: the owner's 2026-11 update note (items ii, ix, x, xvi) and
  `docs/build/06-update-2026-11.md` §2–3.
- Supersedes: ADR-0033 on colours, type and the leaf corner; ADR-0037 §1 on headings and
  §3 on the default appearance. ADR-0037's Bangla metrics (`PaoBanglaScale`) stay.

## 1. Palette

**Decision.** The owner's five colours (Ink `#1C1C1A`, Primary `#16336F`, Soft `#B1BFE2`,
Ground `#F0EEDF`, Action `#FE492A`) become `PaoColors`, extended with the surfaces and dark
values in 06 §2: a canvas of `#F6F4EC`, white cards, Ground for section bands and inputs,
and deep navy-ink surfaces (`#0E1322`, `#151B2D`, `#1B2338`) in dark mode. `AccentPreset.navy`
carries the primary family and is the default; the other ten accents stay selectable.

**Why.** The warm paper and brown dark mode of ADR-0033 read as dull on large areas, which the
owner called out as not premium. Lifting Ground a step for the canvas and putting white cards
on it keeps the owner's warmth while giving the screen contrast and depth. The Action orange
fails contrast as text (3.4:1) and under white labels, so it is `spark` for badges and dots
only, with `sparkInk` and `actionStrong` for the rare orange text or urgent button. Every text
and accent pair is checked against WCAG AA in the tests, in both modes and for every accent.

## 2. Type

**Decision.** iOS uses the system font (SF Pro, Kohinoor Bangla). Android and web bundle Inter
for Latin and Noto Sans Bengali for Bangla. Fraunces and Plus Jakarta Sans are removed. One
scale: display 28, title 22, headline 18, body 16, label 14, caption 12; headings are the body
family at 600–700 with −0.2 letter spacing.

**Why.** The owner asked for "simple fonts like Helvetica or iPhone text". SF Pro and Helvetica
may not be shipped inside an Android or web app, and Inter is the open neutral grotesque drawn
in that tradition. One family for headings and body is calmer than a serif display face, and
16 px body text reads better on the phones PAO's users have. The larger text exposed two
layouts that could not shrink (the home search hint, the admin provider search); both were
fixed rather than the size reduced.

## 3. Light by default

**Decision.** With nothing saved the apps open light, also for existing users who never chose.
Appearance (Light, Dark, Like the phone) is its own page one level into Account (customer) and
Profile (partner), not on the first screen or in onboarding. The admin panel has a Dark mode
switch in its sidebar.

**Why.** The owner wants light as the face of PAO, with dark mode findable but not up front.
Following the phone made half the users meet the dark theme first.

## 4. Surfaces

**Decision.** Cards are white with a navy-tinted two-layer shadow in light mode and edged navy
surfaces in dark mode. Corners are even: 16 for cards, 12 for small elements and inputs, 24
across the top of sheets. The leaf corner with its sharp tip is retired.

**Why.** Shadows tinted with the primary read as part of the palette instead of grey dirt, and
even corners are the calm, professional look the owner asked for; the leaf belonged to the
earlier Nakshi direction that this round replaces.

## Consequences

- `pao_ui/test/goldens/` holds images of every component in light/dark × English/Bangla;
  a visual change has to update them on purpose.
- Older screens that styled text by hand still inherit the new family through the theme;
  P28's design pass catches any that set sizes directly.
