package httpx

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/getkin/kin-openapi/openapi3"

	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

const testSpec = `
openapi: 3.0.3
info: {title: t, version: "1"}
servers: [{url: "http://example.com"}]
paths:
  /v1/things:
    post:
      operationId: createThing
      x-permission: booking:create
      parameters:
        - {name: Idempotency-Key, in: header, required: true, schema: {type: string}}
      requestBody:
        required: true
        content:
          application/json:
            schema: {type: object, required: [n], properties: {n: {type: integer, minimum: 1}}}
      responses: {"201": {description: ok}}
    get:
      operationId: listThings
      responses: {"200": {description: ok}}
`

func newTestRouter(t *testing.T) *SpecRouter {
	t.Helper()
	spec, err := openapi3.NewLoader().LoadFromData([]byte(testSpec))
	if err != nil {
		t.Fatal(err)
	}
	r, err := NewSpecRouter(spec, logx.Discard())
	if err != nil {
		t.Fatal(err)
	}
	return r
}

func TestSpecRouter(t *testing.T) {
	var seen Operation
	h := newTestRouter(t).Middleware(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		seen, _ = OperationFrom(r.Context())
	}))
	tests := []struct {
		name, method, path, body string
		idem                     bool
		status                   int
	}{
		{"valid", http.MethodPost, "/v1/things", `{"n":2}`, true, 200},
		{"invalid body", http.MethodPost, "/v1/things", `{"n":0}`, true, 422},
		{"missing header", http.MethodPost, "/v1/things", `{"n":2}`, false, 422},
		{"unknown path", http.MethodGet, "/v1/nope", "", false, 404},
		{"wrong method", http.MethodDelete, "/v1/things", "", false, 405},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(tc.method, tc.path, strings.NewReader(tc.body))
			req.Header.Set("Content-Type", "application/json")
			if tc.idem {
				req.Header.Set("Idempotency-Key", "abcdefgh")
			}
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			if rec.Code != tc.status {
				t.Fatalf("status = %d, body %s", rec.Code, rec.Body.String())
			}
		})
	}
	if seen.ID != "createThing" || seen.Permission != "booking:create" || !seen.Idempotent {
		t.Fatalf("operation = %+v", seen)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/things", nil))
	if seen.ID != "listThings" || seen.Permission != "" || seen.Idempotent {
		t.Fatalf("operation without x-permission = %+v", seen)
	}
}

func TestNewSpecRouter_RejectsBrokenSpec(t *testing.T) {
	spec := &openapi3.T{OpenAPI: "3.0.3", Paths: openapi3.NewPaths(openapi3.WithPath("/x/{id}", &openapi3.PathItem{
		Get: &openapi3.Operation{Responses: openapi3.NewResponses()},
	}))}
	if _, err := NewSpecRouter(spec, logx.Discard()); err == nil {
		t.Fatal("spec with an undeclared path parameter accepted")
	}
}
