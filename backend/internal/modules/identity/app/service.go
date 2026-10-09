// Package app holds the identity use cases.
package app

import (
	"log/slog"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Deps are the collaborators of the identity use cases.
type Deps struct {
	Repo        port.Repository
	Codes       port.CodeStore
	Sessions    port.Sessions
	Challenges  port.Challenges
	Limiter     port.RateLimiter
	SMS         port.SMSSender
	Signer      port.TokenSigner
	Denylist    port.Denylist
	Permissions port.Permissions
	Levels      port.LevelReader
	Secrets     port.SecretBox
	Keys        port.Keys
	Clock       clock.Clock
	IDs         idgen.Generator
	Log         *slog.Logger
}

// Service implements the identity use cases.
type Service struct{ d Deps }

// New returns the identity service.
func New(d Deps) *Service { return &Service{d: d} }
