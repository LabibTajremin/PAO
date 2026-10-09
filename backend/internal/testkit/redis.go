package testkit

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Redis returns a client for PAO_TEST_REDIS_URL and a key builder with a prefix unique
// to the test, so parallel tests never see each other's keys.
func Redis(t testing.TB) (*redis.Client, redisx.Keys) {
	t.Helper()
	client, err := redisx.Connect(context.Background(), Env(t, "PAO_TEST_REDIS_URL"))
	if err != nil {
		t.Fatalf("redis: %v", err)
	}
	t.Cleanup(func() { _ = client.Close() })
	return client, redisx.NewKeys("test-" + uuid.NewString())
}

// ClosedRedis returns a client whose connection is already closed, to exercise error
// paths.
func ClosedRedis(t testing.TB) *redis.Client {
	t.Helper()
	client := redis.NewClient(&redis.Options{Addr: "127.0.0.1:1", MaxRetries: -1})
	_ = client.Close()
	return client
}
