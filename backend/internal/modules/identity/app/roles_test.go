package app

import (
	"errors"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
)

func TestRoles_ListAndUpdate(t *testing.T) {
	h := newHarness()
	cat, err := h.svc.ListRoles(ctx)
	if err != nil || len(cat.Roles) != 3 || len(cat.AllPermissions) != 3 || len(cat.AllScreens) != 7 {
		t.Fatalf("list: %+v %v", cat, err)
	}
	def := RoleDefinition{Role: "verifier", Grants: rbac.Grants{Permissions: []string{"verification:review", "job:respond"}, Screens: []string{"A05"}}}
	if _, err := h.svc.UpdateRole(ctx, def); err != nil || h.perms.version != 1 || len(h.repo.grants["verifier"].Permissions) != 2 {
		t.Fatalf("update: %v", err)
	}
	for _, bad := range []RoleDefinition{
		{Role: "nobody"},
		{Role: "verifier", Grants: rbac.Grants{Permissions: []string{"made:up"}}},
		{Role: "verifier", Grants: rbac.Grants{Screens: []string{"Z99"}}},
	} {
		if _, err := h.svc.UpdateRole(ctx, bad); !errors.Is(err, domain.ErrRoleInvalid) {
			t.Errorf("%+v accepted", bad)
		}
	}
}

func TestRoles_Failures(t *testing.T) {
	for _, step := range []string{"ListRoles", "LoadGrants", "Catalogue"} {
		h := newHarness()
		h.repo.faults[step] = errBoom
		if _, err := h.svc.ListRoles(ctx); !errors.Is(err, errBoom) {
			t.Errorf("list %s: %v", step, err)
		}
	}
	def := RoleDefinition{Role: "verifier"}
	for _, step := range []string{"ListRoles", "Catalogue", "ReplaceRole", "BumpVersion"} {
		h := newHarness()
		h.repo.faults[step] = errBoom
		h.perms.faults[step] = errBoom
		if _, err := h.svc.UpdateRole(ctx, def); !errors.Is(err, errBoom) {
			t.Errorf("update %s: %v", step, err)
		}
	}
}
