package testkit

import (
	"bytes"
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

// API is a running API server on a private database, Redis prefix and buckets.
type API struct {
	URL string
	// Clock is the fake clock every module uses; advance it to pass rate-limit windows.
	Clock   *clock.Fake
	Infra   *app.Infra
	Modules *app.Modules
	signer  *auth.Signer
}

// Config returns a complete test configuration on the PAO_TEST_* services.
func Config(t testing.TB) config.Config {
	t.Helper()
	s3 := StorageConfig(t)
	_, key, _ := ed25519.GenerateKey(rand.Reader)
	return config.Config{
		AppEnv: config.EnvTest, DatabaseURL: MigratedDatabase(t), RedisURL: Env(t, "PAO_TEST_REDIS_URL"),
		S3: config.S3{Endpoint: s3.Endpoint, PublicEndpoint: s3.Endpoint, Region: s3.Region, AccessKey: s3.AccessKey,
			SecretKey: s3.SecretKey, BucketPrivate: "pao-test-private", BucketPublic: "pao-test-public"},
		JWT:               config.JWT{KeyID: "k1", SigningKey: key},
		DataEncryptionKey: auth.RandomBytes(32), AdminCORSOrigin: "http://admin",
	}
}

// NewAPI starts the full API for a test.
func NewAPI(t testing.TB) *API {
	t.Helper()
	cfg := Config(t)
	infra, err := app.Connect(context.Background(), cfg, logx.Discard())
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	t.Cleanup(infra.Close)
	_, keys := Redis(t)
	clk := clock.NewFake(time.Now().UTC())
	infra.Keys, infra.Clock = keys, clk
	modules, err := app.BuildModules(infra)
	if err != nil {
		t.Fatalf("modules: %v", err)
	}
	spec, _ := api.GetSpec()
	h, err := app.APIHandler(infra, spec, modules.Server, modules.Identity.Permissions)
	if err != nil {
		t.Fatalf("handler: %v", err)
	}
	srv := httptest.NewServer(h)
	t.Cleanup(srv.Close)
	return &API{URL: srv.URL, Clock: clk, Infra: infra, Modules: modules,
		signer: auth.NewSigner("k1", cfg.JWT.SigningKey, 15*time.Minute, infra.Clock, idgen.V7{})}
}

// Response is a decoded API response.
type Response struct {
	Status int
	Header http.Header
	Body   []byte
}

// JSON decodes the body into a generic map.
func (r Response) JSON(t testing.TB) map[string]any {
	t.Helper()
	var m map[string]any
	if err := json.Unmarshal(r.Body, &m); err != nil {
		t.Fatalf("decode %s: %v", r.Body, err)
	}
	return m
}

// Decode decodes the body into v.
func (r Response) Decode(t testing.TB, v any) {
	t.Helper()
	if err := json.Unmarshal(r.Body, v); err != nil {
		t.Fatalf("decode %s: %v", r.Body, err)
	}
}

// Code returns error.code from an error body.
func (r Response) Code(t testing.TB) string {
	t.Helper()
	e, _ := r.JSON(t)["error"].(map[string]any)
	code, _ := e["code"].(string)
	return code
}

// Request is an optional request setting.
type Request func(*http.Request)

// Bearer sets the Authorization header.
func Bearer(token string) Request {
	return func(r *http.Request) { r.Header.Set("Authorization", "Bearer "+token) }
}

// Header sets a header.
func Header(k, v string) Request { return func(r *http.Request) { r.Header.Set(k, v) } }

// Do sends a request; body is JSON-encoded unless nil.
func (a *API) Do(t testing.TB, method, path string, body any, opts ...Request) Response {
	t.Helper()
	var rd io.Reader
	if body != nil {
		raw, _ := json.Marshal(body)
		rd = bytes.NewReader(raw)
	}
	req, _ := http.NewRequest(method, a.URL+path, rd)
	req.Header.Set("Content-Type", "application/json")
	for _, o := range opts {
		o(req)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("%s %s: %v", method, path, err)
	}
	defer func() { _ = resp.Body.Close() }()
	raw, _ := io.ReadAll(resp.Body)
	return Response{Status: resp.StatusCode, Header: resp.Header, Body: raw}
}

// LastCode returns the newest one-time code texted to phone.
func (a *API) LastCode(t testing.TB, phone string) string {
	t.Helper()
	p, _ := domain.NormalizePhone(phone)
	code := regexp.MustCompile(`[0-9]{6}`).FindString(a.Modules.SMSCapture.Last(p))
	if code == "" {
		t.Fatalf("no code sent to %s", phone)
	}
	return code
}

// SignIn performs the OTP flow and returns the token pair.
func (a *API) SignIn(t testing.TB, phone, appKind string) api.TokenPair {
	t.Helper()
	if r := a.Do(t, "POST", "/v1/auth/otp/request", map[string]string{"phone": phone}); r.Status != http.StatusAccepted {
		t.Fatalf("otp request: %d %s", r.Status, r.Body)
	}
	r := a.Do(t, "POST", "/v1/auth/otp/verify", map[string]string{"phone": phone, "code": a.LastCode(t, phone), "app": appKind})
	if r.Status != http.StatusOK {
		t.Fatalf("otp verify: %d %s", r.Status, r.Body)
	}
	var tp api.TokenPair
	r.Decode(t, &tp)
	return tp
}

// SignInAgain waits out the resend timer, then signs in again.
func (a *API) SignInAgain(t testing.TB, phone, appKind string) api.TokenPair {
	t.Helper()
	a.Clock.Advance(domain.ResendAfter)
	return a.SignIn(t, phone, appKind)
}

// Token signs an access token for any subject and roles, bypassing sign-in.
func (a *API) Token(t testing.TB, subject uuid.UUID, roles ...string) string {
	t.Helper()
	return a.TokenWithSession(t, subject, uuid.New(), roles...)
}

// TokenWithSession signs an access token bound to a chosen session (refresh family).
func (a *API) TokenWithSession(t testing.TB, subject, session uuid.UUID, roles ...string) string {
	t.Helper()
	tok, _, err := a.signer.Sign(auth.Claims{Subject: subject, Roles: roles, SessionID: session})
	if err != nil {
		t.Fatal(err)
	}
	return tok
}
