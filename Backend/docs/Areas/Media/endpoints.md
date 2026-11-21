# Media area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).

Errors: `MediaErrorMap` maps `media.invalid` and `media.forbidden` to 422 UPLOAD_INVALID,
`media.not_found` to 404 NOT_FOUND and `media.not_uploaded` to 409 UPLOAD_NOT_FOUND.
[API index](../../Api/README.md).

## MediaControllers

| Controller | Operation | Route | Attribute |
|---|---|---|---|
| `CustomerUploadsController` | createCustomerUpload, confirmCustomerUpload | `POST /v1/customer/uploads`, `POST .../{mediaId}/confirm` | `[AllUserType(Permission = "media:upload")]` |
| `MerchantUploadsController` | createProviderUpload, confirmProviderUpload | `POST /v1/provider/uploads`, `POST .../{mediaId}/confirm` | `[AllUserType(Permission = "media:upload")]` |
| `DocumentsController` | getDocumentViewURL | `GET /v1/admin/documents/{mediaId}/view-url` | `[Admin(Permission = "verification:docs:view")]` |
