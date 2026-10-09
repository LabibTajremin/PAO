package redisx

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// IdempotencyRecord is what is stored under an idempotency key: the request
// fingerprint and, once the first request finished, its response.
type IdempotencyRecord struct {
	RequestHash string `json:"h"`
	Done        bool   `json:"d"`
	Status      int    `json:"s,omitempty"`
	Body        []byte `json:"b,omitempty"`
}

// IdempotencyStore remembers responses for 24 h so retries get the first answer
// (PRD §9.6).
type IdempotencyStore struct {
	rdb redis.Cmdable
	ttl time.Duration
}

// NewIdempotencyStore returns a store keeping records for ttl.
func NewIdempotencyStore(rdb redis.Cmdable, ttl time.Duration) *IdempotencyStore {
	return &IdempotencyStore{rdb: rdb, ttl: ttl}
}

// Reserve claims key for a new request. When the key already exists it returns the
// stored record and reserved=false. SET NX GET makes claim-or-read one atomic step.
func (s *IdempotencyStore) Reserve(ctx context.Context, key, requestHash string) (IdempotencyRecord, bool, error) {
	pending, _ := json.Marshal(IdempotencyRecord{RequestHash: requestHash})
	raw, err := s.rdb.SetArgs(ctx, key, pending, redis.SetArgs{Mode: "NX", Get: true, TTL: s.ttl}).Bytes()
	if errors.Is(err, redis.Nil) {
		return IdempotencyRecord{RequestHash: requestHash}, true, nil
	}
	if err != nil {
		return IdempotencyRecord{}, false, fmt.Errorf("reserve %s: %w", key, err)
	}
	var rec IdempotencyRecord
	if err := json.Unmarshal(raw, &rec); err != nil {
		return IdempotencyRecord{}, false, fmt.Errorf("decode %s: %w", key, err)
	}
	return rec, false, nil
}

// Complete stores the response of the reserved request.
func (s *IdempotencyStore) Complete(ctx context.Context, key string, rec IdempotencyRecord) error {
	rec.Done = true
	raw, _ := json.Marshal(rec)
	if err := s.rdb.Set(ctx, key, raw, s.ttl).Err(); err != nil {
		return fmt.Errorf("complete %s: %w", key, err)
	}
	return nil
}

// Release forgets a reservation whose request failed, so the client may retry.
func (s *IdempotencyStore) Release(ctx context.Context, key string) error {
	if err := s.rdb.Del(ctx, key).Err(); err != nil {
		return fmt.Errorf("release %s: %w", key, err)
	}
	return nil
}
