# Brand in the apps

Where the PAO logo, icons and splash screens come from, how to regenerate them, and what they
look like. The sources are in `design/brand/`; the palette and type are in
[ADR-0038](../adr/0038-navy-trust-palette-neutral-type-light-default.md).

## In the app

| What | Code |
|---|---|
| Logo tile and wordmark, ink on light and ivory on dark | `PaoLogo` in `Frontend/packages/pao_ui/lib/src/widgets/logo.dart` |
| Receipt watermark (6% opacity, ivory on dark) | `PaoWatermark`, same file |
| Receipt header logo, watermark and the "Ask for it. PAO it." footer | `Frontend/apps/customer/lib/features/bookings/presentation/receipt_page.dart`, `…/bookings/data/receipt_pdf.dart`, `Frontend/apps/partner/lib/features/jobs/presentation/receipt_sheet.dart` |
| The SVGs the apps ship | `Frontend/packages/pao_ui/assets/brand/` |

## Icons and splash screens

The launcher icons and splash screens are generated files. Don't edit them by hand; change the
source in `design/brand/` and run:

```bash
tools/brand/app-icons.sh
```

```bash
tools/brand/splash.sh
```

```bash
tools/brand/preview.sh
```

The scripts need ImageMagick and `rsvg-convert` (`apt install imagemagick librsvg2-bin`).
`preview.sh` redraws the pictures on this page from the generated files.

The partner app's icon has an orange wrench badge so the two apps can't be mixed up on a phone.
Its badge sources are in `design/brand/app-icons/partner/`.

### Customer (PAO)

![Customer app icons on Android and iOS](images/brand/icons-customer.png)

![Customer splash, light and dark](images/brand/splash-customer.png)

### Partner (PAO Partner)

![Partner app icons on Android and iOS](images/brand/icons-partner.png)

![Partner splash, light and dark](images/brand/splash-partner.png)

These pictures are drawn from the generated files, not taken on a phone. Check a real install
before a release: on Android, the light and dark home screens and themed icons (Settings ›
Wallpaper & style › Themed icons); on iOS, the light, dark and tinted home screens (long-press the
home screen › Edit › Customize).

## Release files

The two apps' release files, CI artifacts and launcher names are listed in
[release.md](release.md#telling-the-two-apps-apart).
