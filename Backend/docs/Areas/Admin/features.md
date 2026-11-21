# Admin area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Settings` | `ListSettings`, `UpdateSetting` | query/command | SETTING_INVALID; `admin.SettingChanged` for the audit trail; the cache is dropped |
| `Complaints` | `ListComplaints`, `GetComplaint` | query | the queue newest first, by status and assignee |
| `Complaints` | `AssignComplaint`, `CommentOnComplaint`, `ResolveComplaint` | command | only active support agents or super admins; COMPLAINT_INVALID_TRANSITION once resolved; `admin.ComplaintResolved` |
| `Reports` | `ReportProblem` | command | either party against the other; strangers get NOT_FOUND; UPLOAD_INVALID for photos that are not the reporter's confirmed complaint photos; `admin.ComplaintCreated` |
| `Dashboard` | `GetDashboard` | query | cached a minute under `cache:dashboard` |
| `People` | `ListAdminProviders`, `GetAdminProvider`, `ListAdminCustomers`, `GetAdminCustomer` | query | from Merchant, Customer, Verification, Booking, Rating and Audit |
| `People` | `ChangeProviderStatus`, `ChangeCustomerStatus` | command | suspend, ban, reinstate through Identity; CONFLICT for the same status |
