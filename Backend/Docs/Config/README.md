# Configuration

Each concern has one file in `Config/`, bound to a typed options class
(`PAO.Infrastructure/Configuration/Options.cs`) and validated at start
(`ConfigValidator`). Files hold defaults only; secrets come from the environment, either as
`Section__Key` or through the NestJS variable names listed in [variables](variables.md).

| File | Section | Keys |
|---|---|---|
| `app.json` | `App` | `Environment`, `AdminCorsOrigin`, `DataEncryptionKey`, `SeedAdminPassword` |
| `database.json` | `Database` | `Url` |
| `http.json` | `Http` | `Address`, `MetricsAddress`, `MaxBodyBytes`, `RateLimitPerUser`, `RateLimitPerIp`, `RateLimitWindowSeconds` |
| `jobs.json` | `Jobs` | `OutboxRelayIntervalMs`, `OutboxRetentionDays` |
| `jwt.json` | `Jwt` | `KeyId`, `SigningKey`, `PreviousPublicKeys`, `AccessTokenTtlSeconds` |
| `logging.json` | `Logging` | `Level`, `Directory`, `WriteFiles` |
| `push.json` | `Push` | `Adapter`, `FcmCredentialsFile` |
| `redis.json` | `Redis` | `Url` |
| `sms.json` | `Sms` | `Adapter`, `SslWirelessEndpoint`, `SslWirelessApiToken`, `SslWirelessSid`, `TimeoutSeconds` |
| `smtp.json` | `Smtp` | `Host`, `Port`, `UseTls`, `From`, `Username`, `Password` |
| `storage.json` | `Storage` | `Endpoint`, `PublicEndpoint`, `Region`, `AccessKey`, `SecretKey`, `BucketPrivate`, `BucketPublic` |

## Local settings file (`appsettings.Local.json`)

For running the hosts straight from a checkout (`dotnet run`, an IDE) without exporting
variables, copy the example next to `Config/`:

```sh
cp Backend/appsettings.Local.example.json Backend/appsettings.Local.json
```

The example holds every required setting with demo values that match the local compose
stack (`./pao up`): Postgres `pao:pao@localhost:5432/pao`, Redis on `6379`, MinIO on
`9000` with `pao-local` / `change-me-local-only`, the console SMS and log push adapters,
and a public dummy key for both `Jwt:SigningKey` and `App:DataEncryptionKey`.

- **Load order:** `Config/*.json`, then `appsettings.Local.json`, then `Section__Key`
  environment variables, then the variable names in [variables](variables.md). The
  environment still wins.
- **Never in shared environments:** when `APP_ENV` (or `App__Environment`) is `staging`
  or `prod`, the file is ignored even if present. A deployment with a missing secret
  then fails at start instead of running on the public demo keys.
- **Not committed:** `Backend/appsettings.Local.json` is git-ignored. The example is
  covered by a unit test that binds and validates it.
- **Demo admins:** `SeedAdminPassword` is `demo-admin-password`; `migrate seed` uses it
  to create the demo admin users in `dev`.
