// Package http serves the provider's document steps and verification status, and the
// admin review queue and Level 2 sessions.
package http

import (
	"context"
	"net/http"
	"time"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the verification part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the verification handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{
	domain.ErrNotFound:         httpx.ErrNotFound,
	domain.ErrInvalid:          httpx.NewError(http.StatusUnprocessableEntity, "VALIDATION_FAILED", "Check the details and try again."),
	domain.ErrBadDocument:      httpx.NewError(http.StatusUnprocessableEntity, "UPLOAD_INVALID", "Upload the document again."),
	domain.ErrClearanceTooOld:  httpx.NewError(http.StatusUnprocessableEntity, "CLEARANCE_TOO_OLD", "The police clearance must be issued within the last 12 months."),
	domain.ErrNIDBlocked:       httpx.NewError(http.StatusForbidden, "NID_BLOCKED", "This NID cannot be used to register."),
	domain.ErrNotPending:       httpx.NewError(http.StatusConflict, "ITEM_NOT_PENDING", "This item is not waiting for a decision."),
	domain.ErrEnrolmentPending: httpx.NewError(http.StatusConflict, "ENROLMENT_INCOMPLETE", "Finish every required step first."),
	domain.ErrNotEligible:      httpx.NewError(http.StatusConflict, "LEVEL2_NOT_ELIGIBLE", "Level 2 needs a Level 1 provider."),
	domain.ErrCoolingOff:       httpx.NewError(http.StatusConflict, "LEVEL2_COOLING_OFF", "The provider must wait before retrying."),
	domain.ErrSessionClosed:    httpx.NewError(http.StatusConflict, "SESSION_CLOSED", "This session already has a result."),
}

func principal(ctx context.Context) httpx.Principal {
	p, _ := httpx.PrincipalFrom(ctx)
	return p
}

func enrolment(s provider.EnrolmentStatus) api.EnrolmentStatus {
	out := api.EnrolmentStatus{Complete: s.Complete, Submitted: s.Submitted}
	for _, st := range s.Steps {
		out.Steps = append(out.Steps, struct {
			Done     bool              `json:"done"`
			Required bool              `json:"required"`
			Step     api.EnrolmentStep `json:"step"`
		}{Done: st.Done, Required: st.Required, Step: api.EnrolmentStep(st.Step)})
	}
	return out
}

func item(it domain.Item) api.VerificationItem {
	out := api.VerificationItem{Type: api.ItemType(it.Type), Status: api.ItemStatus(it.Status), Required: domain.Required(it.Type),
		DecidedAt: utc(it.DecidedAt), ExpiresAt: utc(it.ExpiresAt)}
	if it.Reason != "" {
		out.RejectionReason = &it.Reason
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

func badge(level int) api.Badge {
	switch level {
	case 2:
		return api.VerifiedPro
	case 1:
		return api.Verified
	}
	return api.None
}

func session(s domain.Session) api.Level2Session {
	out := api.Level2Session{Id: s.ID, ProviderId: s.ProviderID, ServiceId: s.ServiceID, ScheduledAt: s.ScheduledAt.UTC(), Location: s.Location,
		Status: api.Level2SessionStatus(s.Status), DecidedBy: s.DecidedBy}
	if s.Result != "" {
		r := api.Level2Result(s.Result)
		out.Result, out.Notes = &r, &s.Notes
		list := make([]struct {
			Item   string `json:"item"`
			Passed bool   `json:"passed"`
		}, 0, len(s.Checklist))
		for _, c := range s.Checklist {
			list = append(list, struct {
				Item   string `json:"item"`
				Passed bool   `json:"passed"`
			}(c))
		}
		out.Checklist = &list
	}
	return out
}

func status(s app.Status) api.VerificationStatus {
	out := api.VerificationStatus{Level: s.Level, Badge: badge(s.Level), CanReceiveBookings: s.CanReceiveBookings,
		Level2: &api.Level2Info{Eligible: s.Level2Eligible, RetryAfter: utc(s.RetryAfter)}}
	for _, t := range domain.Types {
		out.Items = append(out.Items, item(s.Item(t)))
	}
	if s.NextSession != nil {
		next := session(*s.NextSession)
		out.Level2.NextSession = &next
	}
	return out
}

func page(cursor *string, limit *int) (int, *httpx.Cursor, error) {
	cur, err := httpx.DecodeCursor(cursor)
	return httpx.PageSize(limit), cur, err
}
