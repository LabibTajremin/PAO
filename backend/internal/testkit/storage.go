package testkit

import (
	"context"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/storage"
)

// StorageConfig returns the S3 settings for the test storage service.
func StorageConfig(t testing.TB) storage.Config {
	t.Helper()
	endpoint := Env(t, "PAO_TEST_S3_ENDPOINT")
	return storage.Config{
		Endpoint: endpoint, PublicEndpoint: endpoint, Region: "us-east-1",
		AccessKey: Env(t, "PAO_TEST_S3_ACCESS_KEY"), SecretKey: Env(t, "PAO_TEST_S3_SECRET_KEY"),
	}
}

// Bucket creates a uniquely named bucket for the test.
func Bucket(t testing.TB, s *storage.Store) string {
	t.Helper()
	name := "t-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:20]
	if err := s.EnsureBucket(context.Background(), name); err != nil {
		t.Fatalf("bucket: %v", err)
	}
	return name
}
