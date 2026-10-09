// Package domain holds the platform settings rules (A-10, docs/build/04-decisions.md).
package domain

import (
	"encoding/json"
	"errors"
	"math"
	"slices"
	"strconv"
	"time"

	"github.com/google/uuid"
)

// Settings errors.
var (
	ErrNotFound = errors.New("setting not found")
	ErrInvalid  = errors.New("value does not match the setting's type")
)

// Setting is one admin-editable rule, stored as text and read through its type.
type Setting struct {
	Key         string
	Value       string
	Type        string
	Description string
	UpdatedAt   time.Time
	UpdatedBy   *uuid.UUID
}

// validators read a value per type. Numbers must be non-negative: every setting is a
// duration, count, radius or threshold.
var validators = map[string]func(string) bool{
	"integer": func(v string) bool {
		n, err := strconv.ParseInt(v, 10, 64)
		return err == nil && n >= 0
	},
	"number": func(v string) bool {
		f, err := strconv.ParseFloat(v, 64)
		return err == nil && f >= 0 && !math.IsInf(f, 0)
	},
	"boolean": func(v string) bool {
		_, err := strconv.ParseBool(v)
		return err == nil
	},
	"string":  func(string) bool { return true },
	"geojson": func(v string) bool { return v == "" || isArea(v) },
}

// Validate checks a new value against the setting's type.
func Validate(typ, value string) error {
	if ok := validators[typ]; ok == nil || !ok(value) {
		return ErrInvalid
	}
	return nil
}

// isArea accepts a GeoJSON Polygon or MultiPolygon, the only shapes a service area
// can take (D5).
func isArea(value string) bool {
	var g struct {
		Type        string          `json:"type"`
		Coordinates json.RawMessage `json:"coordinates"`
	}
	if json.Unmarshal([]byte(value), &g) != nil {
		return false
	}
	return slices.Contains([]string{"Polygon", "MultiPolygon"}, g.Type) && len(g.Coordinates) > 2
}
