# Catalog area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).

Errors: `CatalogErrorMap` (in `CatalogControllers.cs`) maps `catalog.not_found` to 404 NOT_FOUND,
`catalog.invalid` to 422 VALIDATION_FAILED and `catalog.price_negative` to 422 VALIDATION_FAILED
`{field: amount}`. [API index](../../Api/README.md).

## CatalogControllers

| Controller | Operation | Route | Attribute |
|---|---|---|---|
| `CustomerCatalogController` | getCatalog | `GET /v1/customer/catalog` | `[AllUserType(Permission = "catalog:read")]` |
| `CustomerCatalogController` | searchCatalog | `GET /v1/customer/catalog/search?q=` | `[AllUserType(Permission = "catalog:read")]` |
| `CustomerCatalogController` | getService | `GET /v1/customer/services/{serviceId}` | `[AllUserType(Permission = "catalog:read")]` |
| `MerchantCatalogController` | getProviderCatalog | `GET /v1/provider/catalog` | `[AllUserType(Permission = "catalog:read")]` |

## AdminCatalogController

Every action: `[Admin(Permission = "catalog:manage")]`.

| Operation | Route |
|---|---|
| getAdminCatalog | `GET /v1/admin/catalog` |
| createCategory, updateCategory | `POST /v1/admin/catalog/categories`, `PUT .../categories/{categoryId}` |
| createService, updateService | `POST /v1/admin/catalog/services`, `PUT .../services/{serviceId}` |
| createSubService, updateSubService | `POST /v1/admin/catalog/sub-services`, `PUT .../sub-services/{subServiceId}` |
| changePrice, listPriceHistory | `POST`, `GET /v1/admin/catalog/sub-services/{subServiceId}/prices` |
