package app

import (
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

var codePattern = regexp.MustCompile(`NewError\([^,]+, "([A-Z0-9_]+)"`)

// TestErrorCodesAreInTheSpec keeps every error code the backend sends inside the
// ErrorCode enum the apps translate (04-decisions.md E11).
func TestErrorCodesAreInTheSpec(t *testing.T) {
	spec, err := api.GetSpec()
	if err != nil {
		t.Fatal(err)
	}
	var known []string
	for _, v := range spec.Components.Schemas["ErrorCode"].Value.Enum {
		known = append(known, v.(string))
	}
	found := 0
	err = filepath.WalkDir("..", func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return err
		}
		src, err := os.ReadFile(path)
		for _, m := range codePattern.FindAllStringSubmatch(string(src), -1) {
			found++
			if !slices.Contains(known, m[1]) {
				t.Errorf("%s: %s is not in the ErrorCode enum", path, m[1])
			}
		}
		return err
	})
	if err != nil || found < 20 {
		t.Fatalf("scanned %d codes: %v", found, err)
	}
}
