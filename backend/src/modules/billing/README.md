# billing

Cash on delivery and merchant dues (ADR-0035). The behaviour is built only in the .NET
backend (`backend-dotnet/PAO.Core/Areas/Billing`, P17 task 5), which replaces this one at
the P17 cut-over. This module only declares the `/v1/provider/billing/...` and
`/v1/admin/billing/...` routes with their spec permissions, so the edge checks and the
contract tests cover them, and answers `501 NOT_IMPLEMENTED`.
