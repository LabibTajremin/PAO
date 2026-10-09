package app

import (
	"strings"
	"testing"

	"github.com/getkin/kin-openapi/openapi3"

	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// sensitive are verification and contact fields that must never reach customers
// (PRD §6.6, §11).
var sensitive = []string{"nidNumber", "documents", "faceMatch", "selfie", "policeClearance", "emergencyContact", "dateOfBirth", "permanentAddress"}

func propertyNames(s *openapi3.SchemaRef, seen map[*openapi3.Schema]bool, out map[string]bool) {
	if s == nil || s.Value == nil || seen[s.Value] {
		return
	}
	v := s.Value
	seen[v] = true
	for name, p := range v.Properties {
		out[name] = true
		propertyNames(p, seen, out)
	}
	propertyNames(v.Items, seen, out)
	for _, group := range [][]*openapi3.SchemaRef{v.AllOf, v.OneOf, v.AnyOf} {
		for _, sub := range group {
			propertyNames(sub, seen, out)
		}
	}
	if v.AdditionalProperties.Schema != nil {
		propertyNames(v.AdditionalProperties.Schema, seen, out)
	}
}

func TestCustomerResponsesNeverExposeVerificationData(t *testing.T) {
	spec, err := api.GetSpec()
	if err != nil {
		t.Fatal(err)
	}
	checked := 0
	for path, item := range spec.Paths.Map() {
		if !strings.HasPrefix(path, "/v1/customer/") && !strings.HasPrefix(path, "/v1/catalog") {
			continue
		}
		for method, op := range item.Operations() {
			names := map[string]bool{}
			for _, resp := range op.Responses.Map() {
				for _, media := range resp.Value.Content {
					propertyNames(media.Schema, map[*openapi3.Schema]bool{}, names)
				}
			}
			for _, field := range sensitive {
				if names[field] {
					t.Errorf("%s %s exposes %s", method, path, field)
				}
			}
			checked++
		}
	}
	if checked < 10 {
		t.Fatalf("only %d customer operations checked", checked)
	}
}
