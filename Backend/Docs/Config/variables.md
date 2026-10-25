# Environment variables

The deployment variable names (`.env.example`) map to settings (`EnvironmentVariables`); an empty value counts as unset.
`Section__Key` variables (for example `Http__RateLimitPerIp`) override any other key.
Validation messages are stable (`DATABASE_URL is required`, …). Back to [Config](README.md).

| Variable | Key | Notes |
|---|---|---|
| `APP_ENV` | `App:Environment` | dev, test, staging, prod; test mounts `/__test/*` |
| `ADMIN_CORS_ORIGIN` | `App:AdminCorsOrigin` | |
| `DATA_ENCRYPTION_KEY` | `App:DataEncryptionKey` | secret, 32 bytes base64 (AES-256-GCM) |
| `SEED_ADMIN_PASSWORD` | `App:SeedAdminPassword` | secret |
| `LOG_LEVEL` | `Logging:Level` | debug, info, warn, error |
| `HTTP_ADDR`, `METRICS_ADDR` | `Http:Address`, `Http:MetricsAddress` | Go `host:port` form |
| `DATABASE_URL` | `Database:Url` | `postgres://` URL with pgxpool pool parameters |
| `REDIS_URL` | `Redis:Url` | `redis://` or `rediss://` |
| `S3_ENDPOINT`, `S3_PUBLIC_ENDPOINT`, `S3_REGION`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_BUCKET_PRIVATE`, `S3_BUCKET_PUBLIC` | `Storage:*` | keys are secrets |
| `JWT_SIGNING_KEY`, `JWT_KEY_ID`, `JWT_PREVIOUS_PUBLIC_KEYS` | `Jwt:*` | seed is a secret |
| `SMS_ADAPTER`, `SSLWIRELESS_API_TOKEN`, `SSLWIRELESS_SID` | `Sms:*` | console or sslwireless |
| `PUSH_ADAPTER`, `FCM_CREDENTIALS_FILE` | `Push:*` | log or fcm |
| `PAO_HOME` | — | folder holding `Config/`, `Logs/`, `DB Changes/` (default: the backend folder or the binaries' folder) |
