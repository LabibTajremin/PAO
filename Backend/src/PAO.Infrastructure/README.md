# PAO.Infrastructure

The platform under the areas: configuration, logging, Redis, crypto, the HTTP edge, the outbox, storage, SMS, push, metrics and health.

External services are reached through small interfaces here (for example `IPushSender`, the SMS sender, storage), so tests swap in fakes.

## Open these first

- `Hosting/PaoPaths.cs`: where config and SQL are found at run time
- `Http/`: the edge (errors, auth, rate limits, the OpenAPI check)
- `Push/`: FCM and its notification channels
