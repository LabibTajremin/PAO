// Package api holds black-box journeys against the running stack (test/e2e/stack.sh):
// plain HTTP to the API and the test-only /__test/ hooks, never internal packages.
package api

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// stack is where the e2e stack listens, read from test/e2e/.stack.env.
var stack struct{ api, worker, adminPassword string }

func TestMain(m *testing.M) {
	env, err := readEnv(filepath.Join("..", ".stack.env"))
	if err != nil {
		fmt.Fprintln(os.Stderr, "start the stack with test/e2e/stack.sh:", err)
		os.Exit(1)
	}
	stack.api, stack.worker, stack.adminPassword = env["PAO_E2E_API"], env["PAO_E2E_WORKER"], env["PAO_E2E_ADMIN_PASSWORD"]
	os.Exit(m.Run())
}

func readEnv(path string) (map[string]string, error) {
	f, err := os.Open(path) //nolint:gosec // a fixed file written by stack.sh
	if err != nil {
		return nil, err
	}
	defer func() { _ = f.Close() }()
	env := map[string]string{}
	for s := bufio.NewScanner(f); s.Scan(); {
		if k, v, ok := strings.Cut(s.Text(), "="); ok {
			env[k] = v
		}
	}
	return env, nil
}
