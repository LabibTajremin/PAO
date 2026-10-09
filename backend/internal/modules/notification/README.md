# notification

Push (FCM), SMS and in-app inbox delivery with Bangla and English templates for every booking and verification event.

## Contract (`contract/service.go`, `NotificationService`)

- `Send`

## Events published

None.

## Events consumed

- `every booking.* event`
- `verification.DocumentRejected`
- `verification.DocumentExpired`
- `verification.DocumentExpiring`
- `verification.ProviderLevelChanged`
- `verification.Level2SessionScheduled`
- `admin.ComplaintResolved`
- `customer.CustomerProfileSaved`
- `identity.AccountDeleted`

## Tables (schema `notification`)

- `notifications`
- `device_tokens`
- `recipients`
- `processed_events`

## HTTP routes

- `/v1/customer/notifications*`
- `/v1/provider/notifications*`
- `/v1/customer/device-token`
- `/v1/provider/device-token`

Migrations: `backend/migrations/notification/`.
