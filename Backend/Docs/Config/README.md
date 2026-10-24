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
