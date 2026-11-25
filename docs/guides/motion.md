# Motion

How PAO moves (P27). Motion explains what happened: where a screen came from and what
changed. It never makes anyone wait, and nothing blocks input while it plays.

## Tokens

Everything animates with `PaoMotion` (`Frontend/packages/pao_ui/lib/src/tokens/motion.dart`).
`./pao lint dart` fails on a raw `Duration(milliseconds: …)` or `Curves.…` in feature, app,
`pao_core` or `pao_ui` widget code; timers in seconds are not motion and stay as they are.

| Token | Value | Used for |
|---|---|---|
| `press` | 100 ms | a finger on a button or card (scale 0.97) |
| `fast` | 150 ms | chips, skeleton → content, admin route fade |
| `base` | 220 ms | tab fade-through, segments, dialog in, the opening's exit |
| `page` / `pop` | 280 / 220 ms | push / pop |
| `sheet` | 300 ms | bottom sheet up (scrim fades with it) |
| `emphasis` | 400 ms | check mark, stepper line, dashboard count-up |
| `letterStagger` / `itemStagger` | 60 / 30 ms | opening letters / first six list items |
| `enter`, `exit` | easeOutCubic, easeInCubic | every enter and leave |
| `emphasized` | Cubic(0.2, 0, 0, 1) | emphasis moments |
| `gentleBack` | Cubic(0.34, 1.3, 0.64, 1) | the logo letters only (≤ 4% overshoot) |

## Which transition

| Moment | Widget | Motion |
|---|---|---|
| Cold start | `PaoOpening` + `OpeningLogo` | first frame = native splash (same colour, 120 dp tile); letters dip to 92% and settle 60 ms apart; the logo rises and fades while the first screen fades in and rises 12 dp; ≈ 560 ms. A slow load keeps the logo with a slim progress line. Warm resume: nothing. |
| Push / pop | `PaoPageTransitionsBuilder` (theme) | shared X axis: slide 24 dp + fade; iOS keeps the native swipe-back |
| Bottom tabs | `PaoFadeThrough` | fade (`base`) |
| Sheet | `showPaoSheet` | slide up (`sheet`) |
| Dialog | `showPaoDialog` | fade + scale 0.96 → 1 |
| Heroes | `PaoHero` | service icon → service page, booking card → detail (surface only), provider photo → profile, sign-in art → code page (`PaoHero.vanish`) |
| Press | `PaoPressable` (in `PaoButton`, tappable `PaoCard`) | scale 0.97; light haptic on primary buttons |
| Loading → content | `ViewStateView` | cross-fade (`fast`) |
| Lists | `PaoEntranceGroup` / `PaoEntrance` (in `PagedView`) | first six items fade and rise 8 dp, 30 ms apart, first load only |
| Booking timeline | `PaoStatusStepper` | the line into the current step fills (`emphasis`) |
| Success | `PaoSuccessMark` | the check draws itself with one burst of palette dots |
| Dashboards | `PaoMoneyText(countUp: true)`, `PaoCountUp` | amounts count up (partner earnings and today) |
| Admin web | theme on web | routes fade (`fast`); dialogs as above |

## Performance rules

- Animate only transform and opacity (`FadeTransition`, `SlideTransition`, `ScaleTransition`,
  `Transform`). Never size, padding, blur, shadows or large clips; no `BackdropFilter`; no
  `Opacity` over large subtrees.
- Wrap animated parts in `RepaintBoundary`; pass static subtrees as `AnimatedBuilder(child:)`;
  `const` widgets; no page-wide `setState` per frame. `PaoSuccessMark` paints from one
  controller with no rebuilds.
- Images decode at display size (`PaoAvatar` uses `ResizeImage`). The opening SVGs are cached
  before `runApp` (`precacheOpening`); look artwork is already in memory (`LookScope`).
- No Lottie or Rive.
- Impeller is on (`EnableImpeller` in both Android manifests; the only renderer on iOS).

## Light motion set

`context.lightMotion` is true when the OS asks for reduced motion
(`MediaQuery.disableAnimations`), on a low-end Android phone (`isLowEndDevice`: low-RAM flag or
under 3 GB, read once at start) and on the admin web when the browser sets
`prefers-reduced-motion`. Then: cross-fades only, durations × 0.7 (`context.motion`), no
stagger, no hero, no burst, no count-up, no opening settle.

Battery saver is not read directly: the plugin that reports it conflicts with
`connectivity_plus`. Android's battery saver usually turns system animations off, which the
first rule already catches.

## Performance test

On a device or emulator in profile mode, with the e2e stack running (`infra/e2e/stack.sh`):

```bash
cd Frontend/apps/customer
```

```bash
flutter drive --profile -d <device> --driver test_driver/perf_driver.dart --target integration_test/perf/motion_perf_test.dart --dart-define=PAO_API_BASE_URL=http://<host>:<port>
```

It traces the opening, five pushes and pops, a tab switch, a sheet and a list fling, writes
`out/perf/motion.timeline_summary.json` (`PAO_PERF_OUT` moves it) and fails when the 90th
percentile build or raster time is 12 ms or more, or any frame takes over 32 ms. Cold start:
`flutter run --profile --trace-startup` writes `build/start_up_info.json`; `timeToFirstFrameMicros`
must stay under 1.5 s.

Reference devices: an Android Go or 2–3 GB phone (Galaxy A05, Redmi A-series) and a mid-range
iPhone. Without one, use an emulator throttled to 2 cores and 2 GB and record the device check
as an owner action in the release notes.
