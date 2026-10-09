package domain

import (
	"errors"
	"testing"
)

func TestValidate(t *testing.T) {
	cases := []struct {
		typ, value string
		ok         bool
	}{
		{"integer", "180", true}, {"integer", "-1", false}, {"integer", "1.5", false},
		{"number", "3.5", true}, {"number", "-0.1", false}, {"number", "Inf", false}, {"number", "x", false},
		{"boolean", "true", true}, {"boolean", "yes", false},
		{"string", "anything", true},
		{"geojson", "", true}, {"geojson", `{"type":"Polygon","coordinates":[[[90,23],[91,23],[91,24],[90,23]]]}`, true},
		{"geojson", `{"type":"Point","coordinates":[90,23]}`, false}, {"geojson", `{"type":"Polygon"}`, false}, {"geojson", "{", false},
		{"unknown", "1", false},
	}
	for _, c := range cases {
		err := Validate(c.typ, c.value)
		if (err == nil) != c.ok || (err != nil && !errors.Is(err, ErrInvalid)) {
			t.Errorf("Validate(%q, %q) = %v", c.typ, c.value, err)
		}
	}
}
