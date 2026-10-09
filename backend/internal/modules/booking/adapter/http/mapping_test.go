package http

import (
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func TestBadge(t *testing.T) {
	if badge(1) != api.Verified || badge(2) != api.VerifiedPro {
		t.Fatal("badge")
	}
}
