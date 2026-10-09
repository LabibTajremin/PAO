// Package http serves the provider's enrolment wizard, profile and presence.
package http

import (
	"context"
	"net/http"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the provider part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the provider handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{
	domain.ErrNotFound:        httpx.ErrNotFound,
	domain.ErrInvalid:         httpx.NewError(http.StatusUnprocessableEntity, "VALIDATION_FAILED", "Check the details and try again."),
	domain.ErrTooYoung:        httpx.NewError(http.StatusUnprocessableEntity, "AGE_REQUIREMENT", "Providers must be at least 18 years old."),
	domain.ErrUnknownService:  httpx.NewError(http.StatusUnprocessableEntity, "SERVICE_UNAVAILABLE", "One of these services is not offered."),
	domain.ErrInvalidPhoto:    httpx.NewError(http.StatusUnprocessableEntity, "UPLOAD_INVALID", "Upload the photo again."),
	domain.ErrCodeRejected:    httpx.NewError(http.StatusUnprocessableEntity, "OTP_INVALID", "The code is wrong or expired."),
	domain.ErrCodeRateLimited: httpx.NewError(http.StatusTooManyRequests, "RATE_LIMITED", "Too many codes. Try again later."),
	domain.ErrContactUnproven: httpx.NewError(http.StatusConflict, "EMERGENCY_CONTACT_MISSING", "Add the emergency contact first."),
	domain.ErrNotVerified:     httpx.NewError(http.StatusForbidden, "NOT_VERIFIED", "You can go online after verification."),
	domain.ErrNoServiceArea:   httpx.NewError(http.StatusConflict, "SERVICE_AREA_MISSING", "Choose your services and area first."),
	domain.ErrOffline:         httpx.NewError(http.StatusConflict, "OFFLINE", "Go online first."),
}

func me(ctx context.Context) uuid.UUID {
	p, _ := httpx.PrincipalFrom(ctx)
	return p.AccountID
}

// Status maps wizard progress to the API shape; verification reuses it.
func Status(p app.Progress) api.EnrolmentStatus {
	out := api.EnrolmentStatus{Complete: p.Complete, Submitted: p.Submitted}
	for _, s := range p.Steps {
		out.Steps = append(out.Steps, struct {
			Done     bool              `json:"done"`
			Required bool              `json:"required"`
			Step     api.EnrolmentStep `json:"step"`
		}{Done: s.Done, Required: s.Required, Step: api.EnrolmentStep(s.Step)})
	}
	return out
}

func status(p app.Progress, err error) (api.EnrolmentStatus, error) {
	if err != nil {
		return api.EnrolmentStatus{}, errorMap.Map(err)
	}
	return Status(p), nil
}

// GetEnrolment implements GET /v1/provider/enrolment.
func (h *Handler) GetEnrolment(ctx context.Context, _ api.GetEnrolmentRequestObject) (api.GetEnrolmentResponseObject, error) {
	s, err := status(h.svc.Enrolment(ctx, me(ctx)))
	if err != nil {
		return nil, err
	}
	return api.GetEnrolment200JSONResponse(s), nil
}

// SavePersonalStep implements PUT /v1/provider/enrolment/personal.
func (h *Handler) SavePersonalStep(ctx context.Context, req api.SavePersonalStepRequestObject) (api.SavePersonalStepResponseObject, error) {
	b := req.Body
	bio := ""
	if b.Bio != nil {
		bio = *b.Bio
	}
	s, err := status(h.svc.SavePersonal(ctx, me(ctx), domain.Personal{FullName: b.FullName, DateOfBirth: b.DateOfBirth.Time, Gender: string(b.Gender),
		PresentAddress: b.PresentAddress, PermanentAddress: b.PermanentAddress, Bio: bio}))
	if err != nil {
		return nil, err
	}
	return api.SavePersonalStep200JSONResponse(s), nil
}

// SaveServicesStep implements PUT /v1/provider/enrolment/services.
func (h *Handler) SaveServicesStep(ctx context.Context, req api.SaveServicesStepRequestObject) (api.SaveServicesStepResponseObject, error) {
	s, err := status(h.svc.SaveServices(ctx, me(ctx), req.Body.ServiceIds, req.Body.ExperienceYears))
	if err != nil {
		return nil, err
	}
	return api.SaveServicesStep200JSONResponse(s), nil
}

// SaveAreaStep implements PUT /v1/provider/enrolment/area.
func (h *Handler) SaveAreaStep(ctx context.Context, req api.SaveAreaStepRequestObject) (api.SaveAreaStepResponseObject, error) {
	home := domain.Point{Lat: req.Body.HomeBase.Lat, Lng: req.Body.HomeBase.Lng}
	s, err := status(h.svc.SaveArea(ctx, me(ctx), home, req.Body.WorkingRadiusM))
	if err != nil {
		return nil, err
	}
	return api.SaveAreaStep200JSONResponse(s), nil
}

// SaveEmergencyContactStep implements PUT /v1/provider/enrolment/emergency-contact.
func (h *Handler) SaveEmergencyContactStep(ctx context.Context, req api.SaveEmergencyContactStepRequestObject) (api.SaveEmergencyContactStepResponseObject, error) {
	c := domain.EmergencyContact{Name: req.Body.Name, Relation: req.Body.Relation, Phone: req.Body.Phone}
	s, err := status(h.svc.SaveEmergencyContact(ctx, me(ctx), c))
	if err != nil {
		return nil, err
	}
	return api.SaveEmergencyContactStep200JSONResponse(s), nil
}

// VerifyEmergencyContact implements POST /v1/provider/enrolment/emergency-contact/verify.
func (h *Handler) VerifyEmergencyContact(ctx context.Context, req api.VerifyEmergencyContactRequestObject) (api.VerifyEmergencyContactResponseObject, error) {
	s, err := status(h.svc.VerifyEmergencyContact(ctx, me(ctx), req.Body.Code))
	if err != nil {
		return nil, err
	}
	return api.VerifyEmergencyContact200JSONResponse(s), nil
}

// SaveCodeOfConductStep implements PUT /v1/provider/enrolment/code-of-conduct.
func (h *Handler) SaveCodeOfConductStep(ctx context.Context, req api.SaveCodeOfConductStepRequestObject) (api.SaveCodeOfConductStepResponseObject, error) {
	s, err := status(h.svc.AcceptCodeOfConduct(ctx, me(ctx), req.Body.Version, req.Body.Accepted))
	if err != nil {
		return nil, err
	}
	return api.SaveCodeOfConductStep200JSONResponse(s), nil
}
