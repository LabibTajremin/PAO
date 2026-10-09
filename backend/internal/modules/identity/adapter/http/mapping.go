package http

import (
	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func tokenPair(s app.Session, includeRefresh bool) api.TokenPair {
	tp := api.TokenPair{AccessToken: s.AccessToken, ExpiresInSeconds: int(s.ExpiresIn.Seconds()), Account: account(s.Account), IsNewAccount: &s.IsNewAccount}
	if includeRefresh {
		tp.RefreshToken = &s.RefreshToken
	}
	return tp
}

func account(a domain.Account) api.Account {
	out := api.Account{Id: a.ID, Roles: roles(a.Roles), Status: api.AccountStatus(a.Status), CreatedAt: a.CreatedAt}
	if a.Phone != "" {
		p := string(a.Phone)
		out.Phone = &p
	}
	if a.Email != "" {
		e := openapi_types.Email(a.Email)
		out.Email = &e
	}
	return out
}

func roles(in []string) []api.Role {
	out := make([]api.Role, len(in))
	for i, r := range in {
		out[i] = api.Role(r)
	}
	return out
}

func adminUser(a domain.Admin) api.AdminUser {
	out := api.AdminUser{Id: a.ID, Email: openapi_types.Email(a.Email), Name: a.Name, Active: a.Active, TotpEnrolled: a.TOTPEnrolled,
		Roles: make([]api.AdminRole, len(a.Roles)), LastLoginAt: a.LastLoginAt}
	for i, r := range a.Roles {
		out.Roles[i] = api.AdminRole(r)
	}
	return out
}

func adminRoleNames(in []api.AdminRole) []string {
	out := make([]string, len(in))
	for i, r := range in {
		out[i] = string(r)
	}
	return out
}

func roleDefinition(r app.RoleDefinition) api.RoleDefinition {
	return api.RoleDefinition{Role: api.Role(r.Role), Permissions: orEmpty(r.Permissions), Screens: orEmpty(r.Screens)}
}

func orEmpty(s []string) []string {
	if s == nil {
		return []string{}
	}
	return s
}

// mustUUID parses IDs the service generated itself, which are always valid.
func mustUUID(s string) uuid.UUID {
	id, _ := uuid.Parse(s)
	return id
}
