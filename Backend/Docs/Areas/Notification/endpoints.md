# Notification area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).

Errors: `NotificationErrorMap` maps `notification.not_found` to 404. [API index](../../Api/README.md).

## NotificationControllers

`CustomerNotificationsController` (`/v1/customer`, app `customer`) and `MerchantNotificationsController` (`/v1/provider`, app `partner`):

| Operation | Route | Attribute |
|---|---|---|
| listCustomerNotifications, listProviderNotifications | `GET .../notifications?cursor&limit` | `[AllUserType(Permission = "notification:read:own")]` |
| markAll...NotificationsRead | `POST .../notifications/read-all` (204) | `[AllUserType(Permission = "notification:read:own")]` |
| mark...NotificationRead | `POST .../notifications/{notificationId}/read` (204) | `[AllUserType(Permission = "notification:read:own")]` |
| register...DeviceToken | `PUT .../device-token` (204) | `[AllUserType(Permission = "device:register")]` |
