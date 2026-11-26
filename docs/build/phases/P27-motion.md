# P27 — Motion: app opening and every transition

**Goal:** the apps open and move smoothly and simply, with a few beautiful details, and they never
feel slow or stutter, including on low-end Android phones.

**Read first:** `06-update-2026-11.md` §9; `pao_ui` theme and widgets; both apps' routers and
`main.dart`; the P21 splash.

## Principles

- Motion explains what happened (where a screen came from, what changed); it is never decoration
  that makes the user wait. Nothing blocks input while it animates.
- Fast and calm: short durations, ease-out on enter, quicker ease-in on exit, almost no overshoot.
- Same rules in the customer app, partner app and admin web.

## Tasks

1. **Motion tokens** in `pao_ui` (`PaoMotion`): durations `press 100 ms`, `fast 150 ms`,
   `base 220 ms`, `page 280 ms` (pop 220 ms), `sheet 300 ms`, `emphasis 400 ms`; curves
   `enter = Curves.easeOutCubic`, `exit = Curves.easeInCubic`,
   `emphasis = Cubic(0.2, 0, 0, 1)`, `gentleBack = Cubic(0.34, 1.3, 0.64, 1)` (overshoot ≤ 4%,
   logo only). No other durations or curves anywhere; a lint/arch test checks for raw
   `Duration(milliseconds:` in feature code.
2. **App opening.** The first Flutter frame is pixel-identical to the native splash (same colour
   and logo position), so there is no flash or jump. Then, on a cold start only: the three logo
   letters settle in one after another (60 ms stagger, `gentleBack`, scale 0.92→1 and fade);
   the logo moves up and fades while the first screen fades in and rises 12 dp. Total ≤ 600 ms,
   running *while* data loads. If loading takes longer, keep the settled logo with a slim progress
   line under it, never a spinner. Warm resume shows no animation.
3. **Page transitions.** Push/pop: shared-axis (slide 24 dp + fade) on Android, native Cupertino
   swipe-back kept on iOS. Bottom-tab switches: fade-through (`base`). Modal sheets: slide up
   with `sheet`, scrim fades in. Dialogs: fade + scale 0.96→1.
4. **Hero moments** (few, chosen): service icon tile → service page header; booking card → booking
   detail; provider avatar → provider profile; sign-in illustration → OTP page (moves up and fades).
5. **Micro-interactions:** buttons and cards scale to 0.97 on press (`press`), with a light
   haptic on primary actions; skeleton → content cross-fade (`fast`); list items fade and rise 8 dp
   with a 30 ms stagger for the first 6 items on first load only; the booking status stepper fills
   its line (`emphasis`); success screens draw the check mark (`emphasis`) with one small burst of
   palette-coloured dots; numbers (prices, earnings) count up only on dashboards.
6. **Performance rules (mandatory):**
   - Animate only `transform` and `opacity` (`FadeTransition`, `SlideTransition`,
     `ScaleTransition`); never animate size, padding, blur, shadows or clipping of large areas;
     no `BackdropFilter`; no `Opacity` widget over large subtrees (use `FadeTransition`).
   - Wrap animated parts in `RepaintBoundary`; build with `AnimatedBuilder(child:)` so the static
     subtree is built once; `const` widgets; no `setState` that rebuilds a whole page per frame.
   - Pre-cache before navigating: the next page's illustration and SVGs (`precacheImage`,
     `flutter_svg` cache), and decode images at display size (`cacheWidth` / `cacheHeight`).
   - No Lottie/Rive files except where they truly add something; if used, ≤ 30 KB each and
     paused when off screen.
   - Impeller enabled on Android and iOS; check for shader-compilation jank in profile mode.
   - **Reduced motion:** when the OS asks for reduced motion (`MediaQuery.disableAnimations`), when
     battery saver is on, or on a low-end device (Android with < 3 GB RAM or
     `ActivityManager.isLowRamDevice`, detected once at start), use the light set: cross-fades
     only, durations × 0.7, no stagger, no hero, no confetti.
7. **Performance tests:**
   - Integration test with `IntegrationTestWidgetsFlutterBinding.traceAction` across app start,
     five page pushes/pops, a sheet, a tab switch and a list scroll, in profile mode. Budgets:
     90th-percentile frame build and raster time < 12 ms, no frame > 32 ms, cold start to first
     frame < 1.5 s on the reference low-end device. Write the summary to `out/perf/`; fail when
     over budget.
   - Reference low-end device: an Android Go / 2–3 GB RAM phone (for example Galaxy A05 or a
     Redmi A-series), plus a mid-range iPhone. If no physical device is available during the run,
     use an emulator throttled to 2 cores / 2 GB and log the manual device check as owner action.
   - Golden/widget tests for reduced-motion mode.
8. **Admin web:** the same tokens; route changes fade (`fast`), panels slide (`base`); respect
   `prefers-reduced-motion`.
9. `docs/guides/motion.md`: the tokens, when to use which transition, the performance rules, and
   how to run the perf test.

## Definition of done

Opening the app and moving between all main screens feels smooth on the low-end reference
device, perf budgets pass, reduced-motion mode works. `./pao ci` green.
