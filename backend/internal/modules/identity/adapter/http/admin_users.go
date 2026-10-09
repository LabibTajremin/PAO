package http

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
)

// ListAdminUsers implements GET /v1/admin/admin-users.
func (h *Handler) ListAdminUsers(ctx context.Context, _ api.ListAdminUsersRequestObject) (api.ListAdminUsersResponseObject, error) {
	admins, err := h.svc.ListAdmins(ctx)
	if err != nil {
		return nil, mapError(err)
	}
	out := api.ListAdminUsers200JSONResponse{Items: make([]api.AdminUser, 0, len(admins))}
	for _, a := range admins {
		out.Items = append(out.Items, adminUser(a))
	}
	return out, nil
}

// InviteAdminUser implements POST /v1/admin/admin-users.
func (h *Handler) InviteAdminUser(ctx context.Context, req api.InviteAdminUserRequestObject) (api.InviteAdminUserResponseObject, error) {
	a, temp, err := h.svc.CreateAdmin(ctx, app.CreateAdminInput{Email: string(req.Body.Email), Name: req.Body.Name, Roles: adminRoleNames(req.Body.Roles)})
	if err != nil {
		return nil, mapError(err)
	}
	return api.InviteAdminUser201JSONResponse{User: adminUser(a), TemporaryPassword: temp}, nil
}

// UpdateAdminUser implements PATCH /v1/admin/admin-users/{adminUserId}.
func (h *Handler) UpdateAdminUser(ctx context.Context, req api.UpdateAdminUserRequestObject) (api.UpdateAdminUserResponseObject, error) {
	in := app.UpdateAdminInput{AdminID: req.AdminUserId, Active: req.Body.Active}
	if req.Body.Roles != nil {
		in.Roles = adminRoleNames(*req.Body.Roles)
	}
	a, err := h.svc.UpdateAdmin(ctx, in)
	if err != nil {
		return nil, mapError(err)
	}
	return api.UpdateAdminUser200JSONResponse(adminUser(a)), nil
}

// ListRoles implements GET /v1/admin/roles.
func (h *Handler) ListRoles(ctx context.Context, _ api.ListRolesRequestObject) (api.ListRolesResponseObject, error) {
	cat, err := h.svc.ListRoles(ctx)
	if err != nil {
		return nil, mapError(err)
	}
	out := api.ListRoles200JSONResponse{AllPermissions: orEmpty(cat.AllPermissions), AllScreens: orEmpty(cat.AllScreens), Items: []api.RoleDefinition{}}
	for _, r := range cat.Roles {
		out.Items = append(out.Items, roleDefinition(r))
	}
	return out, nil
}

// UpdateRole implements PUT /v1/admin/roles/{role}.
func (h *Handler) UpdateRole(ctx context.Context, req api.UpdateRoleRequestObject) (api.UpdateRoleResponseObject, error) {
	def, err := h.svc.UpdateRole(ctx, app.RoleDefinition{Role: string(req.Role), Grants: rbac.Grants{
		Permissions: req.Body.Permissions, Screens: req.Body.Screens,
	}})
	if err != nil {
		return nil, mapError(err)
	}
	return api.UpdateRole200JSONResponse(roleDefinition(def)), nil
}
