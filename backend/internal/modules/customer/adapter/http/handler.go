// Package http serves the customer profile, saved addresses and the launch-area check.
package http

import (
	"context"
	"net/http"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the customer part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the customer handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{
	domain.ErrNotFound:        httpx.NewError(http.StatusNotFound, "PROFILE_NOT_FOUND", "Set up your profile first."),
	domain.ErrAddressNotFound: httpx.ErrNotFound,
	domain.ErrInvalid:         httpx.NewError(http.StatusUnprocessableEntity, "VALIDATION_FAILED", "Check the details and try again."),
	domain.ErrInvalidPhoto:    httpx.NewError(http.StatusUnprocessableEntity, "PHOTO_INVALID", "Upload the photo again."),
	domain.ErrOutsideCountry:  httpx.NewError(http.StatusUnprocessableEntity, "LOCATION_OUTSIDE_BANGLADESH", "Place the pin inside Bangladesh."),
	domain.ErrAddressLimit:    httpx.NewError(http.StatusConflict, "ADDRESS_LIMIT", "You can save up to 10 addresses. Delete one first."),
	domain.ErrProfileRequired: httpx.NewError(http.StatusConflict, "PROFILE_REQUIRED", "Set up your profile first."),
}

func me(ctx context.Context) uuid.UUID {
	p, _ := httpx.PrincipalFrom(ctx)
	return p.AccountID
}

func toProfile(p app.Profile) api.CustomerProfile {
	out := api.CustomerProfile{Id: p.ID, Name: p.Name, Language: api.Language(p.Language), Phone: &p.Phone}
	if p.PhotoURL != "" {
		out.PhotoUrl = &p.PhotoURL
	}
	return out
}

// GetCustomerProfile implements GET /v1/customer/profile.
func (h *Handler) GetCustomerProfile(ctx context.Context, _ api.GetCustomerProfileRequestObject) (api.GetCustomerProfileResponseObject, error) {
	p, err := h.svc.Profile(ctx, me(ctx))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetCustomerProfile200JSONResponse(toProfile(p)), nil
}

// UpdateCustomerProfile implements PUT /v1/customer/profile.
func (h *Handler) UpdateCustomerProfile(ctx context.Context, req api.UpdateCustomerProfileRequestObject) (api.UpdateCustomerProfileResponseObject, error) {
	p, err := h.svc.SaveProfile(ctx, domain.Customer{ID: me(ctx), Name: req.Body.Name, PhotoMediaID: req.Body.PhotoMediaId, Language: string(req.Body.Language)})
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.UpdateCustomerProfile200JSONResponse(toProfile(p)), nil
}

func str(p *string) string {
	if p == nil {
		return ""
	}
	return *p
}

func fromInput(customer, id uuid.UUID, in api.AddressInput) domain.Address {
	return domain.Address{ID: id, CustomerID: customer, Label: string(in.Label), Line1: in.Line1, Line2: str(in.Line2), Area: str(in.Area),
		Location: domain.Point{Lat: in.Location.Lat, Lng: in.Location.Lng}, Default: in.IsDefault != nil && *in.IsDefault}
}

func toAddress(a domain.Address) api.Address {
	return api.Address{Id: a.ID, Label: api.AddressLabel(a.Label), Line1: a.Line1, Line2: &a.Line2, Area: &a.Area,
		Location: api.Point{Lat: a.Location.Lat, Lng: a.Location.Lng}, IsDefault: a.Default}
}

// ListAddresses implements GET /v1/customer/addresses.
func (h *Handler) ListAddresses(ctx context.Context, _ api.ListAddressesRequestObject) (api.ListAddressesResponseObject, error) {
	list, err := h.svc.Addresses(ctx, me(ctx))
	if err != nil {
		return nil, err
	}
	items := make([]api.Address, 0, len(list))
	for _, a := range list {
		items = append(items, toAddress(a))
	}
	return api.ListAddresses200JSONResponse{Items: items}, nil
}

// CreateAddress implements POST /v1/customer/addresses.
func (h *Handler) CreateAddress(ctx context.Context, req api.CreateAddressRequestObject) (api.CreateAddressResponseObject, error) {
	a, err := h.svc.AddAddress(ctx, fromInput(me(ctx), uuid.Nil, *req.Body))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.CreateAddress201JSONResponse(toAddress(a)), nil
}

// UpdateAddress implements PUT /v1/customer/addresses/{addressId}.
func (h *Handler) UpdateAddress(ctx context.Context, req api.UpdateAddressRequestObject) (api.UpdateAddressResponseObject, error) {
	a, err := h.svc.UpdateAddress(ctx, fromInput(me(ctx), req.AddressId, *req.Body))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.UpdateAddress200JSONResponse(toAddress(a)), nil
}

// DeleteAddress implements DELETE /v1/customer/addresses/{addressId}.
func (h *Handler) DeleteAddress(ctx context.Context, req api.DeleteAddressRequestObject) (api.DeleteAddressResponseObject, error) {
	if err := h.svc.DeleteAddress(ctx, me(ctx), req.AddressId); err != nil {
		return nil, errorMap.Map(err)
	}
	return api.DeleteAddress204Response{}, nil
}

// SetDefaultAddress implements POST /v1/customer/addresses/{addressId}/default.
func (h *Handler) SetDefaultAddress(ctx context.Context, req api.SetDefaultAddressRequestObject) (api.SetDefaultAddressResponseObject, error) {
	a, err := h.svc.SetDefault(ctx, me(ctx), req.AddressId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.SetDefaultAddress200JSONResponse(toAddress(a)), nil
}

// CheckServiceArea implements GET /v1/customer/service-area.
func (h *Handler) CheckServiceArea(ctx context.Context, req api.CheckServiceAreaRequestObject) (api.CheckServiceAreaResponseObject, error) {
	ok, err := h.svc.Covered(ctx, geo.Point{Lat: req.Params.Lat, Lng: req.Params.Lng})
	if err != nil {
		return nil, err
	}
	return api.CheckServiceArea200JSONResponse{Covered: ok}, nil
}
