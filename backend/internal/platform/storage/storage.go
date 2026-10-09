// Package storage talks to S3-compatible object storage: presigned uploads and
// downloads, metadata checks and deletes (PRD §6.6). Buckets are private; clients only
// ever get short-lived signed URLs.
package storage

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	smithyhttp "github.com/aws/smithy-go/transport/http"
)

// ErrObjectNotFound is returned when an object does not exist.
var ErrObjectNotFound = errors.New("object not found")

// Config locates the storage service. PublicEndpoint is what devices reach; it differs
// from Endpoint inside Docker.
type Config struct {
	Endpoint       string
	PublicEndpoint string
	Region         string
	AccessKey      string
	SecretKey      string
}

// Store is the S3 adapter.
type Store struct {
	client  *s3.Client
	presign *s3.PresignClient
}

// New builds a store using path-style addressing, which S3-compatible servers need.
func New(cfg Config) *Store {
	creds := credentials.NewStaticCredentialsProvider(cfg.AccessKey, cfg.SecretKey, "")
	build := func(endpoint string) *s3.Client {
		return s3.New(s3.Options{
			Region: cfg.Region, Credentials: creds, BaseEndpoint: aws.String(endpoint), UsePathStyle: true,
			// Presigned uploads come from phones that cannot add SDK checksum headers.
			RequestChecksumCalculation: aws.RequestChecksumCalculationWhenRequired,
		})
	}
	return &Store{client: build(cfg.Endpoint), presign: s3.NewPresignClient(build(cfg.PublicEndpoint))}
}

// ObjectInfo is an object's stored metadata.
type ObjectInfo struct {
	Size        int64
	ContentType string
}

// PresignPut returns a URL that accepts exactly one PUT of size bytes of contentType;
// the signed headers make storage reject anything else.
func (s *Store) PresignPut(ctx context.Context, bucket, key, contentType string, size int64, ttl time.Duration) (string, map[string]string, error) {
	req, err := s.presign.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(bucket), Key: aws.String(key), ContentType: aws.String(contentType), ContentLength: aws.Int64(size),
	}, s3.WithPresignExpires(ttl))
	if err != nil {
		return "", nil, fmt.Errorf("presign put %s/%s: %w", bucket, key, err)
	}
	return req.URL, map[string]string{"Content-Type": contentType}, nil
}

// PresignGet returns a URL that downloads the object until ttl passes.
func (s *Store) PresignGet(ctx context.Context, bucket, key string, ttl time.Duration) (string, error) {
	req, err := s.presign.PresignGetObject(ctx, &s3.GetObjectInput{Bucket: aws.String(bucket), Key: aws.String(key)}, s3.WithPresignExpires(ttl))
	if err != nil {
		return "", fmt.Errorf("presign get %s/%s: %w", bucket, key, err)
	}
	return req.URL, nil
}

// Head returns the object's metadata or ErrObjectNotFound.
func (s *Store) Head(ctx context.Context, bucket, key string) (ObjectInfo, error) {
	out, err := s.client.HeadObject(ctx, &s3.HeadObjectInput{Bucket: aws.String(bucket), Key: aws.String(key)})
	if isNotFound(err) {
		return ObjectInfo{}, ErrObjectNotFound
	}
	if err != nil {
		return ObjectInfo{}, fmt.Errorf("head %s/%s: %w", bucket, key, err)
	}
	return ObjectInfo{Size: aws.ToInt64(out.ContentLength), ContentType: aws.ToString(out.ContentType)}, nil
}

// Delete removes an object; deleting a missing object succeeds.
func (s *Store) Delete(ctx context.Context, bucket, key string) error {
	if _, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{Bucket: aws.String(bucket), Key: aws.String(key)}); err != nil {
		return fmt.Errorf("delete %s/%s: %w", bucket, key, err)
	}
	return nil
}

// EnsureBucket creates the bucket when it is missing and asks for default server-side
// encryption (AES-256), so documents are encrypted at rest (PRD §6.6).
func (s *Store) EnsureBucket(ctx context.Context, bucket string) error {
	_, err := s.client.HeadBucket(ctx, &s3.HeadBucketInput{Bucket: aws.String(bucket)})
	if isNotFound(err) {
		_, err = s.client.CreateBucket(ctx, &s3.CreateBucketInput{Bucket: aws.String(bucket)})
	}
	if err == nil {
		err = s.encrypt(ctx, bucket)
	}
	if err != nil {
		return fmt.Errorf("ensure bucket %s: %w", bucket, err)
	}
	return nil
}

func (s *Store) encrypt(ctx context.Context, bucket string) error {
	_, err := s.client.PutBucketEncryption(ctx, &s3.PutBucketEncryptionInput{
		Bucket: aws.String(bucket),
		ServerSideEncryptionConfiguration: &types.ServerSideEncryptionConfiguration{Rules: []types.ServerSideEncryptionRule{{
			ApplyServerSideEncryptionByDefault: &types.ServerSideEncryptionByDefault{SSEAlgorithm: types.ServerSideEncryptionAes256},
		}}},
	})
	return err
}

// Ping checks that storage answers, for readiness.
func (s *Store) Ping(ctx context.Context, bucket string) error {
	if _, err := s.client.HeadBucket(ctx, &s3.HeadBucketInput{Bucket: aws.String(bucket)}); err != nil {
		return fmt.Errorf("storage ping: %w", err)
	}
	return nil
}

func isNotFound(err error) bool {
	var resp *smithyhttp.ResponseError
	return errors.As(err, &resp) && resp.HTTPStatusCode() == http.StatusNotFound
}
