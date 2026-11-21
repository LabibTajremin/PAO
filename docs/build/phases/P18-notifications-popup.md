# P18 — Notifications that pop up

**Goal:** every push notification (booking, job, billing, admin broadcast) shows as a
heads-up banner on Android and iOS, in background and in foreground, in both apps.

**Read first:** `06-update-2026-11.md` §8; `Backend/src/PAO.Infrastructure/Push/FcmPushSender.cs`;
`Frontend/packages/pao_core/lib/src/device/push.dart`; both apps' `main.dart`.

## Tasks

1. **Channels.** Add `flutter_local_notifications` to `pao_core`. On start, create Android
   channels with `Importance.high` (sound and vibration on): `pao_bookings` (booking and job
   status, new requests), `pao_account` (billing, verification) and `pao_general`
   (broadcasts). Set `com.google.firebase.messaging.default_notification_channel_id` to
   `pao_bookings` in both apps' `AndroidManifest.xml`. Ask for `POST_NOTIFICATIONS` on
   Android 13+ at the right moment (after sign-in, with a short reason sheet), not at launch.
2. **Payload.** `FcmPushSender`: `android.notification.channel_id` from the notification type,
   `android.priority = high`, `notification_priority = PRIORITY_HIGH`, a default sound;
   `apns.headers.apns-priority = 10`, `apns-push-type = alert`,
   `aps.sound = default`, `aps.interruption-level = time-sensitive` for booking/job events and
   `active` for others. A table maps each notification type to its channel; unit-test it.
3. **Foreground.** iOS: `setForegroundNotificationPresentationOptions(alert, badge, sound)`.
   Android: on `onMessage`, show the message through `flutter_local_notifications` on its
   channel (FCM does not display foreground messages on Android). Tapping routes the same as
   a background tap (existing push-tap routing).
4. **iOS capability.** Push Notifications + Background Modes › Remote notifications in both
   Runner targets; Time Sensitive Notifications entitlement.
5. **Tests.** Unit: type→channel mapping, payload shape (C#). Flutter: the push service creates
   channels, shows foreground messages, routes taps (fakes for the plugins). Add a
   `docs/guides/push-testing.md` page: how to check heads-up on a real device, and what to do
   when a user has turned a channel off (a settings deep link from the Notifications page).

## Definition of done

On a real Android 14 phone and an iPhone, a new booking request, a status change and an
admin broadcast all pop up, with the app closed, in background and in foreground.
`./pao ci` green.
