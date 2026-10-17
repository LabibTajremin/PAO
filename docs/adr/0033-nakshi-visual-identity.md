# ADR-0033: Give the apps the "Nakshi" visual identity

- Status: Accepted
- Date: 2026-10-13
- Source: owner request (a distinctive but simple look)

## Context

The apps used Plus Jakarta Sans, standard Material shapes and flat white and grey
surfaces. It worked but looked generic. The owner wants a look that is recognisably
PAO, still calm and simple, with a quiet nod to Bangladeshi craft. The ten accent
themes from Figma stay, and so do every widget API and behaviour.

## Decision

All of the look lives in `pao_ui`; app code does not change.

- **Surfaces.** Warm paper page (`#FAF6EF`), lighter card (`#FFFDF8`), deeper input
  well (`#F2ECE2`), deep ink text (`#1F1B16`) and warm grey secondary text.
  `PaoTheme.dark()` adds a matching deep ink palette. Widgets read mode-aware getters
  on `context.pao`; the old static constants keep their light values for app code.
- **Leaf corner.** Three 22 px corners and a 4 px tip at the bottom right (top right on sheets,
  whose bottom edge is hidden) (`PaoShape`)
  on cards, buttons, sheets, dialogs, selected chips and icon tiles. Hairline borders
  replace shadows.
- **Kantha stitch.** A thin dashed accent line at 50% opacity, drawn by
  `PaoStitchPainter`. It is used sparingly: section dividers, the active bottom-nav
  item, the status-timeline connector and the empty-state frame.
- **Type.** Fraunces (variable, OFL, bundled) for display, headline and title-large;
  Plus Jakarta Sans for everything else. Hind Siliguri stays the fallback of both.
  Money uses tabular figures.
- **Details.** Pill badges with a leading dot, 52 px buttons, filled inputs with an
  accent focus border, 150–200 ms eased transitions.
- **Accessibility.** A test checks WCAG AA (4.5:1) for text on every surface and for
  every accent's action, selected and tint pairs, in both modes. Dark mode uses each
  accent's `soft` tone for actions because the accents are too dark on ink.

## Consequences

- Apps stay on `PaoTheme.light()`. Turning on dark mode needs app screens to stop
  using the static `PaoColors` constants first.
- The empty-state frame and titles were sized to the old footprint so screens with
  fixed-height boxes still fit. Snack bars keep the fixed placement.
- Fraunces adds about 360 KB to each app.
