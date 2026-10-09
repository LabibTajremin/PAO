package app

import (
	"context"
	"errors"
	"slices"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
)

var errBoom = errors.New("boom")

// faults injects an error into the named fake method.
type faults map[string]error

func (f faults) check(name string) error { return f[name] }

type fakeRepo struct {
	faults
	accounts map[uuid.UUID]domain.Account
	admins   map[uuid.UUID]domain.Admin
	blocked  map[domain.Phone]bool
	grants   map[string]rbac.Grants
	events   []eventbus.Event
	clock    clock.Clock
}

func newFakeRepo(clk clock.Clock) *fakeRepo {
	return &fakeRepo{faults: faults{}, accounts: map[uuid.UUID]domain.Account{}, admins: map[uuid.UUID]domain.Admin{},
		blocked: map[domain.Phone]bool{}, clock: clk,
		grants: map[string]rbac.Grants{
			"customer": {Permissions: []string{"booking:create"}, Screens: []string{"C01", "C07"}},
			"provider": {Permissions: []string{"job:respond"}, Screens: []string{"M01", "M14", "M15", "M28"}},
			"verifier": {Permissions: []string{"verification:review"}, Screens: []string{"A05"}},
		}}
}

func (r *fakeRepo) AccountByID(_ context.Context, id uuid.UUID) (domain.Account, error) {
	if err := r.check("AccountByID"); err != nil {
		return domain.Account{}, err
	}
	a, ok := r.accounts[id]
	if !ok {
		return domain.Account{}, domain.ErrAccountNotFound
	}
	return a, nil
}

func (r *fakeRepo) AccountByPhone(_ context.Context, p domain.Phone) (domain.Account, error) {
	if err := r.check("AccountByPhone"); err != nil {
		return domain.Account{}, err
	}
	for _, a := range r.accounts {
		if a.Phone == p {
			return a, nil
		}
	}
	return domain.Account{}, domain.ErrAccountNotFound
}

func (r *fakeRepo) AdminByEmail(_ context.Context, email string) (domain.Admin, error) {
	if err := r.check("AdminByEmail"); err != nil {
		return domain.Admin{}, err
	}
	for _, a := range r.admins {
		if a.Email == email {
			return a, nil
		}
	}
	return domain.Admin{}, domain.ErrAccountNotFound
}

func (r *fakeRepo) AdminByID(_ context.Context, id uuid.UUID) (domain.Admin, error) {
	if err := r.check("AdminByID"); err != nil {
		return domain.Admin{}, err
	}
	a, ok := r.admins[id]
	if !ok {
		return domain.Admin{}, domain.ErrAccountNotFound
	}
	return a, nil
}

func (r *fakeRepo) ListAdmins(context.Context) ([]domain.Admin, error) {
	out := make([]domain.Admin, 0, len(r.admins))
	for _, a := range r.admins {
		out = append(out, a)
	}
	return out, r.check("ListAdmins")
}

func (r *fakeRepo) IsPhoneBlocked(_ context.Context, p domain.Phone) (bool, error) {
	return r.blocked[p], r.check("IsPhoneBlocked")
}

func (r *fakeRepo) ListRoles(context.Context) ([]string, error) {
	names := make([]string, 0, len(r.grants))
	for n := range r.grants {
		names = append(names, n)
	}
	slices.Sort(names)
	return names, r.check("ListRoles")
}

func (r *fakeRepo) LoadGrants(_ context.Context, role string) (rbac.Grants, error) {
	return r.grants[role], r.check("LoadGrants")
}

func (r *fakeRepo) Catalogue(context.Context) ([]string, []string, error) {
	return []string{"booking:create", "job:respond", "verification:review"}, []string{"A05", "C01", "C07", "M01", "M14", "M15", "M28"}, r.check("Catalogue")
}

func (r *fakeRepo) InTx(_ context.Context, fn func(tx port.TxRepository) error) error {
	if err := r.check("InTx"); err != nil {
		return err
	}
	return fn(r)
}

func (r *fakeRepo) CreateAccount(_ context.Context, a domain.Account) error {
	if err := r.check("CreateAccount"); err != nil {
		return err
	}
	a.Roles = nil
	r.accounts[a.ID] = a
	return nil
}

func (r *fakeRepo) GrantRole(_ context.Context, id uuid.UUID, role string) error {
	if err := r.check("GrantRole"); err != nil {
		return err
	}
	a := r.accounts[id]
	a.Roles = append(a.Roles, role)
	r.accounts[id] = a
	return nil
}

func (r *fakeRepo) SetRoles(_ context.Context, id uuid.UUID, roles []string) error {
	if err := r.check("SetRoles"); err != nil {
		return err
	}
	a := r.accounts[id]
	a.Roles = roles
	r.accounts[id] = a
	return nil
}

func (r *fakeRepo) UpdateStatus(_ context.Context, id uuid.UUID, s domain.Status) error {
	if err := r.check("UpdateStatus"); err != nil {
		return err
	}
	a := r.accounts[id]
	a.Status = s
	r.accounts[id] = a
	return nil
}

func (r *fakeRepo) BlockPhone(_ context.Context, p domain.Phone, _ string) error {
	r.blocked[p] = true
	return r.check("BlockPhone")
}

func (r *fakeRepo) UnblockPhone(_ context.Context, p domain.Phone) error {
	delete(r.blocked, p)
	return r.check("UnblockPhone")
}

func (r *fakeRepo) AnonymiseAccount(_ context.Context, id uuid.UUID) error {
	if err := r.check("AnonymiseAccount"); err != nil {
		return err
	}
	a := r.accounts[id]
	now := r.clock.Now()
	a.Phone, a.DeletedAt = "", &now
	r.accounts[id] = a
	return nil
}

func (r *fakeRepo) CreateAdminCredentials(_ context.Context, id uuid.UUID, hash string) error {
	if err := r.check("CreateAdminCredentials"); err != nil {
		return err
	}
	r.admins[id] = domain.Admin{Account: r.accounts[id], PasswordHash: hash, MustChangePassword: true, Active: true}
	return nil
}

func (r *fakeRepo) SaveAdmin(_ context.Context, a domain.Admin) error {
	if err := r.check("SaveAdmin"); err != nil {
		return err
	}
	r.admins[a.ID] = a
	return nil
}

func (r *fakeRepo) ReplaceRole(_ context.Context, role string, perms, screens []string) error {
	r.grants[role] = rbac.Grants{Permissions: perms, Screens: screens}
	return r.check("ReplaceRole")
}

func (r *fakeRepo) Publish(_ context.Context, _ string, e eventbus.Event) error {
	r.events = append(r.events, e)
	return r.check("Publish")
}
