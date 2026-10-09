//go:build integration

package storage_test

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/platform/storage"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func put(t *testing.T, url string, headers map[string]string, body []byte) int {
	t.Helper()
	req, _ := http.NewRequest(http.MethodPut, url, bytes.NewReader(body))
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	b, _ := io.ReadAll(resp.Body)
	_ = resp.Body.Close()
	if resp.StatusCode != 200 {
		t.Logf("PUT %s -> %s", url, b)
	}
	return resp.StatusCode
}

func TestStore_UploadViewDelete(t *testing.T) {
	ctx := context.Background()
	s := storage.New(testkit.StorageConfig(t))
	bucket := testkit.Bucket(t, s)
	if err := s.EnsureBucket(ctx, bucket); err != nil {
		t.Fatalf("ensure existing bucket: %v", err)
	}
	body := []byte("fake-jpeg-bytes")
	url, headers, err := s.PresignPut(ctx, bucket, "docs/a.jpg", "image/jpeg", int64(len(body)), 5*time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	if code := put(t, url, headers, body); code != 200 {
		t.Fatalf("upload status %d", code)
	}
	info, err := s.Head(ctx, bucket, "docs/a.jpg")
	if err != nil || info.Size != int64(len(body)) || info.ContentType != "image/jpeg" {
		t.Fatalf("head: %+v %v", info, err)
	}
	get, err := s.PresignGet(ctx, bucket, "docs/a.jpg", 5*time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	resp, err := http.Get(get)
	if err != nil || resp.StatusCode != 200 {
		t.Fatalf("download: %v", err)
	}
	_ = resp.Body.Close()
	if err := s.Delete(ctx, bucket, "docs/a.jpg"); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Head(ctx, bucket, "docs/a.jpg"); !errors.Is(err, storage.ErrObjectNotFound) {
		t.Fatalf("after delete: %v", err)
	}
	if err := s.Ping(ctx, bucket); err != nil {
		t.Fatal(err)
	}
}

func TestStore_Errors(t *testing.T) {
	ctx := context.Background()
	cfg := testkit.StorageConfig(t)
	cfg.SecretKey = "wrong"
	bad := storage.New(cfg)
	if err := bad.EnsureBucket(ctx, "t-nope"); err == nil {
		t.Fatal("bad credentials created a bucket")
	}
	if _, err := bad.Head(ctx, "t-nope", "k"); err == nil {
		t.Fatal("bad credentials read metadata")
	}
	if err := bad.Delete(ctx, "t-nope", "k"); err == nil {
		t.Fatal("bad credentials deleted")
	}
	if err := bad.Ping(ctx, "t-nope"); err == nil {
		t.Fatal("bad credentials pinged")
	}
	cfg.AccessKey, cfg.SecretKey = "", ""
	anonymous := storage.New(cfg)
	if _, _, err := anonymous.PresignPut(ctx, "b", "k", "image/jpeg", 1, time.Minute); err == nil {
		t.Fatal("presigned a put without credentials")
	}
	if _, err := anonymous.PresignGet(ctx, "b", "k", time.Minute); err == nil {
		t.Fatal("presigned a get without credentials")
	}
}
