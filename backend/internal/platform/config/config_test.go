package config

import (
	"crypto/ed25519"
	"encoding/base64"
	"log/slog"
	"strings"
	"testing"
)

func validEnv() map[string]string {
	seed := base64.StdEncoding.EncodeToString(make([]byte, 32))
	return map[string]string{
		"DATABASE_URL": "postgres://x", "REDIS_URL": "redis://x",
		"S3_ENDPOINT": "http://s3", "S3_ACCESS_KEY": "a", "S3_SECRET_KEY": "b",
		"S3_BUCKET_PRIVATE": "p", "S3_BUCKET_PUBLIC": "q",
		"JWT_SIGNING_KEY": seed, "DATA_ENCRYPTION_KEY": seed,
	}
}

func load(env map[string]string) (Config, error) {
	return Load(func(k string) string { return env[k] })
}

func TestLoad_DefaultsFromMinimalEnv(t *testing.T) {
	c, err := load(validEnv())
	if err != nil {
		t.Fatal(err)
	}
	if c.AppEnv != EnvDev || c.HTTPAddr != ":8080" || c.S3.PublicEndpoint != "http://s3" ||
		c.LogLevel != slog.LevelInfo || len(c.JWT.SigningKey) != ed25519.PrivateKeySize || c.JWT.KeyID != "k1" {
		t.Fatalf("unexpected config: %+v", c)
	}
}

func TestLoad_ReportsEveryMissingVariable(t *testing.T) {
	_, err := load(map[string]string{})
	for _, name := range []string{"DATABASE_URL", "REDIS_URL", "S3_ENDPOINT", "JWT_SIGNING_KEY", "DATA_ENCRYPTION_KEY"} {
		if err == nil || !strings.Contains(err.Error(), name) {
			t.Errorf("error %v does not mention %s", err, name)
		}
	}
}

func TestLoad_RejectsInvalidValues(t *testing.T) {
	tests := map[string]map[string]string{
		"bad env":       {"APP_ENV": "qa"},
		"bad level":     {"LOG_LEVEL": "loud"},
		"short key":     {"DATA_ENCRYPTION_KEY": "c2hvcnQ="},
		"not base64":    {"JWT_SIGNING_KEY": "%%%"},
		"bad previous":  {"JWT_PREVIOUS_PUBLIC_KEYS": "k0:nope"},
		"sms creds":     {"SMS_ADAPTER": "sslwireless"},
		"fcm creds":     {"PUSH_ADAPTER": "fcm"},
		"prod fake sms": {"APP_ENV": EnvProd},
	}
	for name, overrides := range tests {
		t.Run(name, func(t *testing.T) {
			env := validEnv()
			for k, v := range overrides {
				env[k] = v
			}
			if _, err := load(env); err == nil {
				t.Fatal("expected an error")
			}
		})
	}
}

func TestLoad_ReadsAdaptersAndPreviousKeys(t *testing.T) {
	env := validEnv()
	pub := base64.StdEncoding.EncodeToString(make([]byte, 32))
	env["JWT_PREVIOUS_PUBLIC_KEYS"] = "k0:" + pub + ","
	env["SMS_ADAPTER"], env["SSLWIRELESS_API_TOKEN"], env["SSLWIRELESS_SID"] = "sslwireless", "t", "s"
	env["PUSH_ADAPTER"], env["FCM_CREDENTIALS_FILE"] = "fcm", "/creds.json"
	env["APP_ENV"], env["LOG_LEVEL"] = EnvProd, "debug"
	c, err := load(env)
	if err != nil {
		t.Fatal(err)
	}
	if len(c.JWT.PreviousKeys["k0"]) != 32 || c.SSLWireless.SID != "s" || c.FCMCredentialsFile != "/creds.json" || c.LogLevel != slog.LevelDebug {
		t.Fatalf("unexpected config: %+v", c)
	}
}

func TestLogValue_OmitsSecrets(t *testing.T) {
	c, _ := load(validEnv())
	c.S3.SecretKey = "super-secret"
	if v := c.LogValue().String(); strings.Contains(v, "super-secret") || !strings.Contains(v, "app_env") {
		t.Fatalf("log value = %s", v)
	}
}
