package app

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

type fakeCodes struct {
	faults
	codes map[string]domain.StoredCode
}

func (c *fakeCodes) Save(_ context.Context, key string, sc domain.StoredCode, _ time.Duration) error {
	c.codes[key] = sc
	return c.check("Save")
}

func (c *fakeCodes) Get(_ context.Context, key string) (domain.StoredCode, error) {
	sc, ok := c.codes[key]
	if !ok {
		return sc, domain.ErrCodeExpired
	}
	return sc, c.check("Get")
}

func (c *fakeCodes) IncrementAttempts(_ context.Context, key string) error {
	sc := c.codes[key]
	sc.Attempts++
	c.codes[key] = sc
	return c.check("IncrementAttempts")
}

func (c *fakeCodes) Delete(_ context.Context, key string) error {
	delete(c.codes, key)
	return c.check("Delete")
}

type fakeSessions struct {
	faults
	families map[uuid.UUID]domain.Family
}

func (s *fakeSessions) Save(_ context.Context, f domain.Family, _ time.Duration) error {
	if err := s.check("Save"); err != nil {
		return err
	}
	s.families[f.ID] = f
	return nil
}

func (s *fakeSessions) Get(_ context.Context, id uuid.UUID) (domain.Family, error) {
	if err := s.check("Get"); err != nil {
		return domain.Family{}, err
	}
	f, ok := s.families[id]
	if !ok {
		return f, domain.ErrRefreshInvalid
	}
	return f, nil
}

func (s *fakeSessions) Delete(_ context.Context, f domain.Family) error {
	delete(s.families, f.ID)
	return s.check("Delete")
}

func (s *fakeSessions) ListForAccount(_ context.Context, id uuid.UUID) ([]domain.Family, error) {
	var out []domain.Family
	for _, f := range s.families {
		if f.AccountID == id {
			out = append(out, f)
		}
	}
	return out, s.check("ListForAccount")
}

type fakeChallenges struct {
	faults
	items map[string]domain.Challenge
}

func (c *fakeChallenges) Save(_ context.Context, ch domain.Challenge, _ time.Duration) error {
	c.items[ch.ID] = ch
	return c.check("Save")
}

func (c *fakeChallenges) Get(_ context.Context, id string) (domain.Challenge, error) {
	ch, ok := c.items[id]
	if !ok {
		return ch, domain.ErrChallengeExpired
	}
	return ch, nil
}

func (c *fakeChallenges) Delete(_ context.Context, id string) error {
	delete(c.items, id)
	return c.check("Delete")
}

type fakeLimiter struct {
	faults
	blockKey string
}

func (l *fakeLimiter) Allow(_ context.Context, key string, _ int, _ time.Duration) (redisx.Decision, error) {
	if err := l.check("Allow"); err != nil {
		return redisx.Decision{}, err
	}
	if l.blockKey != "" && key == l.blockKey {
		return redisx.Decision{RetryAfter: 42 * time.Second}, nil
	}
	return redisx.Decision{Allowed: true}, nil
}

type fakeSMS struct {
	faults
	last map[domain.Phone]string
}

func (s *fakeSMS) Send(_ context.Context, p domain.Phone, msg string) error {
	s.last[p] = msg
	return s.check("Send")
}

type fakeDenylist struct {
	faults
	denied []string
}

func (d *fakeDenylist) Deny(_ context.Context, jti string, _ time.Duration) error {
	d.denied = append(d.denied, jti)
	return d.check("Deny")
}

type fakePermissions struct {
	faults
	repo    *fakeRepo
	version int64
}

func (p *fakePermissions) Grants(ctx context.Context, roles []string) (rbac.Grants, error) {
	if err := p.check("Grants"); err != nil {
		return rbac.Grants{}, err
	}
	var g rbac.Grants
	for _, r := range roles {
		rg := p.repo.grants[r]
		g.Permissions = append(g.Permissions, rg.Permissions...)
		g.Screens = append(g.Screens, rg.Screens...)
	}
	return g, nil
}

func (p *fakePermissions) Version(context.Context) (int64, error) {
	return p.version, p.check("Version")
}

func (p *fakePermissions) BumpVersion(context.Context) (int64, error) {
	p.version++
	return p.version, p.check("BumpVersion")
}

type fakeLevels struct {
	faults
	level int
}

func (l *fakeLevels) GetLevel(context.Context, uuid.UUID) (int, error) {
	return l.level, l.check("GetLevel")
}

type fakeSigner struct {
	faults
	signer *auth.Signer
}

func (s *fakeSigner) Sign(c auth.Claims) (string, auth.Claims, error) {
	if err := s.check("Sign"); err != nil {
		return "", auth.Claims{}, err
	}
	return s.signer.Sign(c)
}

type fakeBox struct{ faults }

func (fakeBox) Encrypt(p []byte) []byte { return append([]byte("enc:"), p...) }

func (b fakeBox) Decrypt(d []byte) ([]byte, error) { return d[4:], b.check("Decrypt") }

// harness bundles the service with its fakes.
type harness struct {
	svc        *Service
	clock      *clock.Fake
	repo       *fakeRepo
	codes      *fakeCodes
	sessions   *fakeSessions
	challenges *fakeChallenges
	limiter    *fakeLimiter
	sms        *fakeSMS
	deny       *fakeDenylist
	perms      *fakePermissions
	levels     *fakeLevels
	signer     *fakeSigner
	box        *fakeBox
}

func newHarness() *harness {
	clk := clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC))
	repo := newFakeRepo(clk)
	_, key, _ := ed25519Key()
	h := &harness{
		clock: clk, repo: repo,
		codes:      &fakeCodes{faults: faults{}, codes: map[string]domain.StoredCode{}},
		sessions:   &fakeSessions{faults: faults{}, families: map[uuid.UUID]domain.Family{}},
		challenges: &fakeChallenges{faults: faults{}, items: map[string]domain.Challenge{}},
		limiter:    &fakeLimiter{faults: faults{}},
		sms:        &fakeSMS{faults: faults{}, last: map[domain.Phone]string{}},
		deny:       &fakeDenylist{faults: faults{}},
		perms:      &fakePermissions{faults: faults{}, repo: repo},
		levels:     &fakeLevels{faults: faults{}},
		signer:     &fakeSigner{faults: faults{}, signer: auth.NewSigner("k1", key, domain.AccessTTL, clk, idgen.V7{})},
		box:        &fakeBox{faults: faults{}},
	}
	h.svc = New(Deps{
		Repo: repo, Codes: h.codes, Sessions: h.sessions, Challenges: h.challenges, Limiter: h.limiter,
		SMS: h.sms, Signer: h.signer, Denylist: h.deny, Permissions: h.perms, Levels: h.levels,
		Secrets: h.box, Keys: redisx.NewKeys("t"), Clock: clk, IDs: idgen.V7{}, Log: logx.Discard(),
	})
	return h
}
