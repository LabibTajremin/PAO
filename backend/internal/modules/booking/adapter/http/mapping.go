// Package http serves bookings from both sides, provider earnings and discovery.
package http

import (
	"context"
	"net/http"
	"slices"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the booking part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the booking handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{
	domain.ErrNotFound:          httpx.ErrNotFound,
	domain.ErrInvalid:           httpx.NewError(http.StatusUnprocessableEntity, "VALIDATION_FAILED", "Check the booking details."),
	domain.ErrInvalidTransition: httpx.NewError(http.StatusConflict, "BOOKING_INVALID_TRANSITION", "The booking has moved on."),
	domain.ErrDeadlinePassed:    httpx.NewError(http.StatusConflict, "ACCEPT_DEADLINE_PASSED", "The time to answer has passed."),
	domain.ErrActiveJob:         httpx.NewError(http.StatusConflict, "ACTIVE_JOB_EXISTS", "Finish your current job first."),
	domain.ErrCodeWrong:         httpx.NewError(http.StatusUnprocessableEntity, "START_CODE_INVALID", "The start code is wrong."),
	domain.ErrCodeLocked:        httpx.NewError(http.StatusConflict, "START_CODE_LOCKED", "Too many wrong codes. Try again later."),
	domain.ErrCashNotConfirmed:  httpx.NewError(http.StatusUnprocessableEntity, "CASH_CONFIRMATION_REQUIRED", "Confirm that you received the cash."),
	domain.ErrExtrasPending:     httpx.NewError(http.StatusConflict, "EXTRAS_PENDING", "The customer has not answered the extra items yet."),
	domain.ErrNoProposal:        httpx.NewError(http.StatusConflict, "NO_PENDING_EXTRAS", "There are no extra items waiting."),
	domain.ErrNotBookable:       httpx.NewError(http.StatusConflict, "PROVIDER_UNAVAILABLE", "This provider cannot take the booking now."),
	domain.ErrDuplicateRequest:  httpx.NewError(http.StatusConflict, "DUPLICATE_BOOKING_REQUEST", "You already asked this provider."),
	domain.ErrCancelNotAllowed:  httpx.NewError(http.StatusConflict, "CANCELLATION_NOT_ALLOWED", "The job has started; report a problem instead."),
	domain.ErrOutsideArea:       httpx.NewError(http.StatusUnprocessableEntity, "OUTSIDE_SERVICE_AREA", "This address is outside our service area."),
	domain.ErrProfileRequired:   httpx.NewError(http.StatusConflict, "PROFILE_REQUIRED", "Set up your profile first."),
}

func principal(ctx context.Context) httpx.Principal {
	p, _ := httpx.PrincipalFrom(ctx)
	return p
}

func text(t domain.Text) api.LocalizedText { return api.LocalizedText{En: t.EN, Bn: t.BN} }

func line(l domain.Line) api.BookingItem {
	return api.BookingItem{SubServiceId: l.SubServiceID, PriceVersionId: l.PriceVersionID, Name: text(l.Name), Unit: api.PriceUnit(l.Unit),
		Quantity: l.Quantity, UnitPrice: l.UnitPaisa, Total: l.TotalPaisa, Extra: l.Extra}
}

func lines(ls []domain.Line) []api.BookingItem {
	out := make([]api.BookingItem, 0, len(ls))
	for _, l := range ls {
		out = append(out, line(l))
	}
	return out
}

func utc(t *time.Time) *time.Time {
	if t == nil {
		return nil
	}
	u := t.UTC()
	return &u
}

// shared reports whether contact details and the exact address are visible to the
// other side: only after acceptance and while the job is live or done (PRD §5, §11).
func shared(b domain.Booking) bool {
	return b.AcceptedAt != nil && (slices.Contains(domain.Active, b.Status) || b.Status == domain.Completed)
}

func party(p domain.Party, show bool) *api.BookingParty {
	out := &api.BookingParty{Id: p.ID, Name: p.Name}
	if show {
		out.Phone = &p.Phone
	}
	return out
}
