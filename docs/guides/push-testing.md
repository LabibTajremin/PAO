# Checking that notifications pop up

Notifications should drop down as a banner (Android calls it "heads-up") for every
type: booking requests and status changes, account and billing messages, and admin
broadcasts. That needs things set up on three sides, and if any one is missing the
notification lands quietly in the tray instead. This page shows how to check it on a
real phone. Emulators and simulators don't behave the same way here, so only trust a
real device.

## What makes a notification pop up

| Where | What | Code |
|---|---|---|
| Backend | Every push names its channel (`pao_bookings`, `pao_account` or `pao_general`), with high priority and a sound; on iOS it sends APNs priority 10 and an alert push type, and booking events are time-sensitive | `Backend/src/PAO.Infrastructure/Push/PushChannels.cs`, `FcmPushSender.Payload` |
| Android app | The three channels are created at start with high importance; `pao_bookings` is FCM's default channel (`AndroidManifest.xml`); messages that arrive while the app is open are shown by the app, because FCM doesn't show those on Android | `pao_core/lib/src/device/local_notifications.dart`, `push.dart` |
| iOS app | Push Notifications and Time Sensitive entitlements, the remote-notification background mode, and foreground presentation options | `ios/Runner/Runner.entitlements`, `Info.plist` |

A new notification type has to be added to `PushChannels`; a unit test fails until it is.

## Before you test

- Use a build with the Firebase values set (`PAO_FCM_*`, see `docs/guides/release.md`).
  Without them the app runs with push switched off.
- iOS: the App IDs `bd.pao.pao_customer` and `bd.pao.pao_partner` (and their `.dev` and
  `.staging` versions) need **Push Notifications** and **Time Sensitive Notifications** turned
  on in the Apple Developer portal, and the provisioning profiles need to be regenerated after
  that. The APNs key has to be uploaded to the Firebase project.
- Sign in. After sign-in the app explains why it wants notifications and then the phone asks.
  Allow it.

## The check

Run each of these three times: with the app **closed** (swiped away), in the
**background** (home screen), and **open**. Each one should drop down as a banner with a sound.

1. **New booking request** (partner app): book a service from the customer app with a
   provider who is online.
2. **Status change** (customer app): have the provider accept the booking, then tap
   "On the way".
3. **Admin broadcast** (both apps): send one from the admin panel, if the build has
   broadcasts; otherwise use the Firebase console's "Send test message" with the data
   `type` set to anything that isn't a booking type. It goes to `pao_general`.

Tapping a banner should open the booking it is about, whether the app was closed or open.

## When it doesn't pop up

- **Android: it only shows in the tray.** Long-press the notification and open its
  settings. If the channel is set to "Silent", the user (or an earlier build) changed it.
  Android remembers channel settings, and an app cannot raise them again. Reinstall the app,
  or turn "Pop on screen" back on for that channel.
- **Android 13+: nothing arrives at all.** The notification permission was declined. The
  Notifications page in both apps then shows "Notifications are off" with a **Turn on**
  button that opens the phone's settings for PAO.
- **iOS: nothing arrives in a TestFlight build.** Usually the APNs key isn't in Firebase,
  or the profile was made before Push Notifications was enabled on the App ID.
- **iOS: it arrives but doesn't break through Focus.** Check that the Time Sensitive
  entitlement is in the profile. The user can also turn it off per app in Settings ›
  Notifications.
- **Any platform: check what the backend sent.** In the test stack (`APP_ENV=test`, which
  `infra/e2e/stack.sh` uses) the backend records every push instead of sending it, and
  `GET /__test/pushes?token=<device token>` shows each one's type and data. Against real FCM,
  the worker and API logs show each send and any error FCM returned.
