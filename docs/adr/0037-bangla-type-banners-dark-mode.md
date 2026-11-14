# ADR-0037: Bangla type, home banners and dark mode

- Status: Accepted
- Date: 2026-11-14
- Source: owner review of the first build: Bangla text was small and some letters were cut,
  the home had no banner, there was no dark theme.
- Amends: ADR-0027 and ADR-0033 on the Bangla font.

## 1. Bangla type

**Decision.** Noto Sans Bengali (variable, OFL) replaces Hind Siliguri. In English it is the
fallback for Bangla words and ৳; when the app language is Bangla it leads, at 1.12× the
Latin size with the line height raised by 0.3 (`PaoBanglaScale`), and headings use bold
Noto instead of Fraunces. The theme takes `bangla:` from the active locale.

**Why.** Bengali vowel signs sit above and below the line; at Latin metrics the tallest
marks were clipped and the text read small. Noto's variable file has full conjunct coverage
and one file serves every weight, so the bundle is smaller than four Hind weights.

## 2. Home banners

**Decision.** `catalog.banners` holds bilingual title and subtitle, an optional https image
URL, an optional service to open, a sort order and a published flag. Admins manage them on
the panel's Home banners page (opened from Catalog, screen A03); the customer app reads
`GET /v1/customer/banners`. A demo banner is seeded by the migration. Images are https URLs
for now; uploading through the media service is a follow-up, as its links expire.

## 3. Dark mode

**Decision.** The customer and partner apps offer System, Light and Dark (default System) on
their language page, saved on the device (`ThemeModeController`, key `pao.theme`). The admin
web follows the browser's setting. Widgets take colours from `context.pao` (ink, card,
hairline, dangerInk and the like), never the light-only constants, so text stays readable
in both palettes.

**Why.** Following the phone needs no setting for most people; the choice is there for those
who want one app different from the rest.
