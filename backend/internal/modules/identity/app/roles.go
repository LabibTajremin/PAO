package app

import (
	"context"
	"slices"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
)

// RoleDefinition is a role with its grants.
type RoleDefinition struct {
	Role string
	rbac.Grants
}

// RoleCatalogue lists every role plus every known permission and screen (A-10).
type RoleCatalogue struct {
	Roles          []RoleDefinition
	AllPermissions []string
	AllScreens     []string
}

// ListRoles returns the role editor's data.
func (s *Service) ListRoles(ctx context.Context) (RoleCatalogue, error) {
	names, err := s.d.Repo.ListRoles(ctx)
	if err != nil {
		return RoleCatalogue{}, err
	}
	var out RoleCatalogue
	for _, name := range names {
		g, err := s.d.Repo.LoadGrants(ctx, name)
		if err != nil {
			return RoleCatalogue{}, err
		}
		out.Roles = append(out.Roles, RoleDefinition{Role: name, Grants: g})
	}
	out.AllPermissions, out.AllScreens, err = s.d.Repo.Catalogue(ctx)
	return out, err
}

// UpdateRole replaces a role's permissions and screens and bumps the RBAC version so
// every cached grant refreshes (02-architecture §6).
func (s *Service) UpdateRole(ctx context.Context, def RoleDefinition) (RoleDefinition, error) {
	names, err := s.d.Repo.ListRoles(ctx)
	if err != nil {
		return RoleDefinition{}, err
	}
	perms, screens, err := s.d.Repo.Catalogue(ctx)
	if err != nil {
		return RoleDefinition{}, err
	}
	if !slices.Contains(names, def.Role) || !subset(def.Permissions, perms) || !subset(def.Screens, screens) {
		return RoleDefinition{}, domain.ErrRoleInvalid
	}
	err = s.d.Repo.InTx(ctx, func(tx port.TxRepository) error {
		return tx.ReplaceRole(ctx, def.Role, def.Permissions, def.Screens)
	})
	if err != nil {
		return RoleDefinition{}, err
	}
	_, err = s.d.Permissions.BumpVersion(ctx)
	return def, err
}

func subset(items, known []string) bool {
	for _, i := range items {
		if !slices.Contains(known, i) {
			return false
		}
	}
	return true
}
