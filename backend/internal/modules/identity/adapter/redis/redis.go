// Package redis keeps identity's short-lived state in Redis: one-time codes, refresh
// token families and admin login challenges (docs/build/02-architecture.md §4).
package redis

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/google/uuid"
	goredis "github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Codes implements port.CodeStore.
type Codes struct{ rdb goredis.Cmdable }

// NewCodes returns the code store.
func NewCodes(rdb goredis.Cmdable) *Codes { return &Codes{rdb: rdb} }

// Save stores a code hash with a fresh attempt counter.
func (c *Codes) Save(ctx context.Context, key string, sc domain.StoredCode, ttl time.Duration) error {
	pipe := c.rdb.TxPipeline()
	pipe.Del(ctx, key)
	pipe.HSet(ctx, key, "h", sc.Hash, "a", sc.Attempts)
	pipe.Expire(ctx, key, ttl)
	_, err := pipe.Exec(ctx)
	return err
}

// Get returns the stored code or domain.ErrCodeExpired.
func (c *Codes) Get(ctx context.Context, key string) (domain.StoredCode, error) {
	m, err := c.rdb.HGetAll(ctx, key).Result()
	if err != nil {
		return domain.StoredCode{}, err
	}
	if m["h"] == "" {
		return domain.StoredCode{}, domain.ErrCodeExpired
	}
	attempts, _ := strconv.Atoi(m["a"])
	return domain.StoredCode{Hash: m["h"], Attempts: attempts}, nil
}

// IncrementAttempts counts a wrong guess.
func (c *Codes) IncrementAttempts(ctx context.Context, key string) error {
	return c.rdb.HIncrBy(ctx, key, "a", 1).Err()
}

// Delete discards a code.
func (c *Codes) Delete(ctx context.Context, key string) error { return c.rdb.Del(ctx, key).Err() }

// Sessions implements port.Sessions: rt:{familyID} hashes indexed by sess:{accountID}.
type Sessions struct {
	rdb  goredis.Cmdable
	keys redisx.Keys
}

// NewSessions returns the session store.
func NewSessions(rdb goredis.Cmdable, keys redisx.Keys) *Sessions {
	return &Sessions{rdb: rdb, keys: keys}
}

func (s *Sessions) familyKey(id uuid.UUID) string  { return s.keys.Key("rt", id.String()) }
func (s *Sessions) accountKey(id uuid.UUID) string { return s.keys.Key("sess", id.String()) }

// Save stores the family and indexes it under its account.
func (s *Sessions) Save(ctx context.Context, f domain.Family, ttl time.Duration) error {
	pipe := s.rdb.TxPipeline()
	pipe.HSet(ctx, s.familyKey(f.ID), "account", f.AccountID.String(), "app", f.App, "hash", f.CurrentHash,
		"jti", f.AccessJTI, "exp", f.AccessExp.UnixMilli())
	pipe.Expire(ctx, s.familyKey(f.ID), ttl)
	pipe.SAdd(ctx, s.accountKey(f.AccountID), f.ID.String())
	pipe.Expire(ctx, s.accountKey(f.AccountID), ttl)
	_, err := pipe.Exec(ctx)
	return err
}

// Get returns a family or domain.ErrRefreshInvalid.
func (s *Sessions) Get(ctx context.Context, id uuid.UUID) (domain.Family, error) {
	m, err := s.rdb.HGetAll(ctx, s.familyKey(id)).Result()
	if err != nil {
		return domain.Family{}, err
	}
	account, err := uuid.Parse(m["account"])
	if err != nil {
		return domain.Family{}, domain.ErrRefreshInvalid
	}
	exp, _ := strconv.ParseInt(m["exp"], 10, 64)
	return domain.Family{ID: id, AccountID: account, App: m["app"], CurrentHash: m["hash"], AccessJTI: m["jti"],
		AccessExp: time.UnixMilli(exp).UTC()}, nil
}

// Delete removes a family.
func (s *Sessions) Delete(ctx context.Context, f domain.Family) error {
	pipe := s.rdb.TxPipeline()
	pipe.Del(ctx, s.familyKey(f.ID))
	pipe.SRem(ctx, s.accountKey(f.AccountID), f.ID.String())
	_, err := pipe.Exec(ctx)
	return err
}

// ListForAccount returns the account's live families, dropping index entries whose
// family already expired.
func (s *Sessions) ListForAccount(ctx context.Context, accountID uuid.UUID) ([]domain.Family, error) {
	ids, err := s.rdb.SMembers(ctx, s.accountKey(accountID)).Result()
	if err != nil {
		return nil, err
	}
	var out []domain.Family
	for _, raw := range ids {
		id, _ := uuid.Parse(raw)
		f, err := s.Get(ctx, id)
		if errors.Is(err, domain.ErrRefreshInvalid) {
			s.rdb.SRem(ctx, s.accountKey(accountID), raw)
			continue
		}
		if err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, nil
}

// Challenges implements port.Challenges (mfa:{id}).
type Challenges struct {
	rdb  goredis.Cmdable
	keys redisx.Keys
}

// NewChallenges returns the challenge store.
func NewChallenges(rdb goredis.Cmdable, keys redisx.Keys) *Challenges {
	return &Challenges{rdb: rdb, keys: keys}
}

// Save stores a challenge for ttl.
func (c *Challenges) Save(ctx context.Context, ch domain.Challenge, ttl time.Duration) error {
	raw, _ := json.Marshal(ch)
	return c.rdb.Set(ctx, c.keys.Key("mfa", ch.ID), raw, ttl).Err()
}

// Get returns a challenge or domain.ErrChallengeExpired.
func (c *Challenges) Get(ctx context.Context, id string) (domain.Challenge, error) {
	raw, err := c.rdb.Get(ctx, c.keys.Key("mfa", id)).Bytes()
	if errors.Is(err, goredis.Nil) {
		return domain.Challenge{}, domain.ErrChallengeExpired
	}
	if err != nil {
		return domain.Challenge{}, err
	}
	var ch domain.Challenge
	if err := json.Unmarshal(raw, &ch); err != nil {
		return domain.Challenge{}, fmt.Errorf("decode challenge: %w", err)
	}
	return ch, nil
}

// Delete removes a challenge.
func (c *Challenges) Delete(ctx context.Context, id string) error {
	return c.rdb.Del(ctx, c.keys.Key("mfa", id)).Err()
}
