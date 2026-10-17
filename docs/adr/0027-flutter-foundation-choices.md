# ADR-0027: Flutter foundation choices

- Status: Accepted
- Date: 2026-10-09
- Source: docs/build/phases/P10-flutter-foundation.md; Figma `Cover & Theme` page

## Context

The Figma file defines the `Accent` modes and the neutral `Base` tokens (canvas
`#F5F6F8`, surface `#FFFFFF`, border `#E5E7EB`, text `#0F172A`/`#475569`/`#94A3B8`,
danger `#DC2626`) but no success or warning colour, and the apps must work offline on
low-end phones.

## Decision

- Success is `#16A34A` and warning `#D97706`, from the same Tailwind-derived palette as
  the Figma danger and slate tokens.
- Plus Jakarta Sans (variable) and Hind Siliguri are bundled in `pao_ui/fonts` under the
  SIL Open Font License instead of being fetched at runtime.
- Skeleton loaders are static: shimmer animations cost battery on low-end phones.
- Bangla is the default language; `LocaleController` switches it at runtime.
- Signed-in users who open sign-in or welcome-back are sent home by the route guard.
- Photos are compressed in pure Dart (`package:image`) so the code is testable on every
  platform without a native plugin.

## Consequences

Font files add about 1.3 MB to each app. Changing the status colours later is a token
change in `pao_ui/lib/src/tokens/colors.dart`.
