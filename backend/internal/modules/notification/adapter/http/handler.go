// Package http serves the notification inbox and device registration of both apps.
package http

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the notification part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the notification handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{domain.ErrNotFound: httpx.ErrNotFound}

func me(ctx context.Context) uuid.UUID {
	p, _ := httpx.PrincipalFrom(ctx)
	return p.AccountID
}

func (h *Handler) inbox(ctx context.Context, appName string, cursor *string, limit *int) (api.NotificationList, error) {
	cur, err := httpx.DecodeCursor(cursor)
	if err != nil {
		return api.NotificationList{}, err
	}
	size := httpx.PageSize(limit)
	p := port.Page{Limit: size + 1}
	if cur != nil {
		p.At, p.ID = &cur.CreatedAt, cur.ID
	}
	in, err := h.svc.Inbox(ctx, me(ctx), appName, p)
	if err != nil {
		return api.NotificationList{}, err
	}
	out := api.NotificationList{Items: []api.Notification{}, UnreadCount: in.Unread}
	for i, n := range in.Items {
		if i == size {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: in.Items[i-1].CreatedAt, ID: in.Items[i-1].ID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, api.Notification{Id: n.ID, Type: n.Type, Title: n.Title, Body: n.Body, BookingId: n.BookingID,
			Read: n.Read, CreatedAt: n.CreatedAt.UTC()})
	}
	return out, nil
}

// ListCustomerNotifications implements GET /v1/customer/notifications.
func (h *Handler) ListCustomerNotifications(ctx context.Context, req api.ListCustomerNotificationsRequestObject) (api.ListCustomerNotificationsResponseObject, error) {
	out, err := h.inbox(ctx, "customer", req.Params.Cursor, req.Params.Limit)
	if err != nil {
		return nil, err
	}
	return api.ListCustomerNotifications200JSONResponse(out), nil
}

// ListProviderNotifications implements GET /v1/provider/notifications.
func (h *Handler) ListProviderNotifications(ctx context.Context, req api.ListProviderNotificationsRequestObject) (api.ListProviderNotificationsResponseObject, error) {
	out, err := h.inbox(ctx, "partner", req.Params.Cursor, req.Params.Limit)
	if err != nil {
		return nil, err
	}
	return api.ListProviderNotifications200JSONResponse(out), nil
}

// MarkCustomerNotificationRead implements POST /v1/customer/notifications/{notificationId}/read.
func (h *Handler) MarkCustomerNotificationRead(ctx context.Context, req api.MarkCustomerNotificationReadRequestObject) (api.MarkCustomerNotificationReadResponseObject, error) {
	if err := h.svc.MarkRead(ctx, me(ctx), "customer", req.NotificationId); err != nil {
		return nil, errorMap.Map(err)
	}
	return api.MarkCustomerNotificationRead204Response{}, nil
}

// MarkProviderNotificationRead implements POST /v1/provider/notifications/{notificationId}/read.
func (h *Handler) MarkProviderNotificationRead(ctx context.Context, req api.MarkProviderNotificationReadRequestObject) (api.MarkProviderNotificationReadResponseObject, error) {
	if err := h.svc.MarkRead(ctx, me(ctx), "partner", req.NotificationId); err != nil {
		return nil, errorMap.Map(err)
	}
	return api.MarkProviderNotificationRead204Response{}, nil
}

// MarkAllCustomerNotificationsRead implements POST /v1/customer/notifications/read-all.
func (h *Handler) MarkAllCustomerNotificationsRead(ctx context.Context, _ api.MarkAllCustomerNotificationsReadRequestObject) (api.MarkAllCustomerNotificationsReadResponseObject, error) {
	if err := h.svc.MarkAllRead(ctx, me(ctx), "customer"); err != nil {
		return nil, err
	}
	return api.MarkAllCustomerNotificationsRead204Response{}, nil
}

// MarkAllProviderNotificationsRead implements POST /v1/provider/notifications/read-all.
func (h *Handler) MarkAllProviderNotificationsRead(ctx context.Context, _ api.MarkAllProviderNotificationsReadRequestObject) (api.MarkAllProviderNotificationsReadResponseObject, error) {
	if err := h.svc.MarkAllRead(ctx, me(ctx), "partner"); err != nil {
		return nil, err
	}
	return api.MarkAllProviderNotificationsRead204Response{}, nil
}

// RegisterCustomerDeviceToken implements PUT /v1/customer/device-token.
func (h *Handler) RegisterCustomerDeviceToken(ctx context.Context, req api.RegisterCustomerDeviceTokenRequestObject) (api.RegisterCustomerDeviceTokenResponseObject, error) {
	if err := h.svc.RegisterDevice(ctx, me(ctx), "customer", req.Body.Token, string(req.Body.Platform)); err != nil {
		return nil, err
	}
	return api.RegisterCustomerDeviceToken204Response{}, nil
}

// RegisterProviderDeviceToken implements PUT /v1/provider/device-token.
func (h *Handler) RegisterProviderDeviceToken(ctx context.Context, req api.RegisterProviderDeviceTokenRequestObject) (api.RegisterProviderDeviceTokenResponseObject, error) {
	if err := h.svc.RegisterDevice(ctx, me(ctx), "partner", req.Body.Token, string(req.Body.Platform)); err != nil {
		return nil, err
	}
	return api.RegisterProviderDeviceToken204Response{}, nil
}
