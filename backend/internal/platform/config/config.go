// Package config loads the typed runtime configuration from environment variables and
// validates it at start-up, failing with every problem at once (P02 task 1).
package config

import (
	"crypto/ed25519"
	"errors"
	"log/slog"
	"strings"
)

// Environment names.
const (
	EnvDev     = "dev"
	EnvTest    = "test"
	EnvStaging = "staging"
	EnvProd    = "prod"
)

// Config is everything the API and worker read from the environment.
type Config struct {
	AppEnv      string
	LogLevel    slog.Level
	HTTPAddr    string
	MetricsAddr string
	DatabaseURL string
	RedisURL    string
	S3          S3
	JWT         JWT
	// DataEncryptionKey is the AES-256 key for encrypted fields (NID, TOTP secrets).
	DataEncryptionKey  []byte
	AdminCORSOrigin    string
	SMSAdapter         string
	SSLWireless        SSLWireless
	PushAdapter        string
	FCMCredentialsFile string
	SeedAdminPassword  string
}

// S3 configures object storage.
type S3 struct {
	Endpoint       string
	PublicEndpoint string
	Region         string
	AccessKey      string
	SecretKey      string
	BucketPrivate  string
	BucketPublic   string
}

// JWT holds the signing key and the public keys still accepted during rotation.
type JWT struct {
	KeyID        string
	SigningKey   ed25519.PrivateKey
	PreviousKeys map[string]ed25519.PublicKey
}

// SSLWireless holds the production SMS gateway credentials.
type SSLWireless struct {
	APIToken string
	SID      string
}

// Load reads and validates the configuration through getenv (os.Getenv in main).
func Load(getenv func(string) string) (Config, error) {
	r := reader{getenv: getenv}
	c := Config{
		AppEnv:            r.oneOf("APP_ENV", EnvDev, EnvDev, EnvTest, EnvStaging, EnvProd),
		LogLevel:          r.level("LOG_LEVEL"),
		HTTPAddr:          r.optional("HTTP_ADDR", ":8080"),
		MetricsAddr:       r.optional("METRICS_ADDR", ":9090"),
		DatabaseURL:       r.required("DATABASE_URL"),
		RedisURL:          r.required("REDIS_URL"),
		S3:                r.s3(),
		JWT:               r.jwt(),
		DataEncryptionKey: r.key("DATA_ENCRYPTION_KEY", 32),
		AdminCORSOrigin:   r.optional("ADMIN_CORS_ORIGIN", "http://localhost:5000"),
		SMSAdapter:        r.oneOf("SMS_ADAPTER", "console", "console", "sslwireless"),
		PushAdapter:       r.oneOf("PUSH_ADAPTER", "log", "log", "fcm"),
		SeedAdminPassword: getenv("SEED_ADMIN_PASSWORD"),
	}
	if c.SMSAdapter == "sslwireless" {
		c.SSLWireless = SSLWireless{APIToken: r.required("SSLWIRELESS_API_TOKEN"), SID: r.required("SSLWIRELESS_SID")}
	}
	if c.PushAdapter == "fcm" {
		c.FCMCredentialsFile = r.required("FCM_CREDENTIALS_FILE")
	}
	if c.AppEnv == EnvProd && (c.SMSAdapter == "console" || c.PushAdapter == "log") {
		r.fail("production needs real SMS_ADAPTER and PUSH_ADAPTER")
	}
	if len(r.problems) > 0 {
		return Config{}, errors.New("invalid configuration: " + strings.Join(r.problems, "; "))
	}
	return c, nil
}

// LogValue implements slog.LogValuer and never includes secrets.
func (c Config) LogValue() slog.Value {
	return slog.GroupValue(
		slog.String("app_env", c.AppEnv),
		slog.String("http_addr", c.HTTPAddr),
		slog.String("sms_adapter", c.SMSAdapter),
		slog.String("push_adapter", c.PushAdapter),
		slog.String("jwt_key_id", c.JWT.KeyID),
	)
}
