package http

import (
	"context"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func step(s provider.EnrolmentStatus, err error) (api.EnrolmentStatus, error) {
	if err != nil {
		return api.EnrolmentStatus{}, errorMap.Map(err)
	}
	return enrolment(s), nil
}

// SaveNidStep implements PUT /v1/provider/enrolment/nid.
func (h *Handler) SaveNidStep(ctx context.Context, req api.SaveNidStepRequestObject) (api.SaveNidStepResponseObject, error) {
	b := req.Body
	s, err := step(h.svc.SaveNID(ctx, principal(ctx).AccountID, b.NidNumber, b.FrontMediaId, b.BackMediaId))
	if err != nil {
		return nil, err
	}
	return api.SaveNidStep200JSONResponse(s), nil
}

// SaveSelfieStep implements PUT /v1/provider/enrolment/selfie.
func (h *Handler) SaveSelfieStep(ctx context.Context, req api.SaveSelfieStepRequestObject) (api.SaveSelfieStepResponseObject, error) {
	s, err := step(h.svc.SaveSelfie(ctx, principal(ctx).AccountID, req.Body.MediaId))
	if err != nil {
		return nil, err
	}
	return api.SaveSelfieStep200JSONResponse(s), nil
}

// SavePoliceClearanceStep implements PUT /v1/provider/enrolment/police-clearance.
func (h *Handler) SavePoliceClearanceStep(ctx context.Context, req api.SavePoliceClearanceStepRequestObject) (api.SavePoliceClearanceStepResponseObject, error) {
	s, err := step(h.svc.SavePoliceClearance(ctx, principal(ctx).AccountID, req.Body.MediaId, req.Body.IssueDate.Time))
	if err != nil {
		return nil, err
	}
	return api.SavePoliceClearanceStep200JSONResponse(s), nil
}

// SaveSkillProofStep implements PUT /v1/provider/enrolment/skill-proof.
func (h *Handler) SaveSkillProofStep(ctx context.Context, req api.SaveSkillProofStepRequestObject) (api.SaveSkillProofStepResponseObject, error) {
	s, err := step(h.svc.SaveSkillProof(ctx, principal(ctx).AccountID, req.Body.MediaIds))
	if err != nil {
		return nil, err
	}
	return api.SaveSkillProofStep200JSONResponse(s), nil
}

// SubmitEnrolment implements POST /v1/provider/enrolment/submit.
func (h *Handler) SubmitEnrolment(ctx context.Context, _ api.SubmitEnrolmentRequestObject) (api.SubmitEnrolmentResponseObject, error) {
	s, err := h.svc.Submit(ctx, principal(ctx).AccountID)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.SubmitEnrolment200JSONResponse(status(s)), nil
}

// GetVerificationStatus implements GET /v1/provider/verification.
func (h *Handler) GetVerificationStatus(ctx context.Context, _ api.GetVerificationStatusRequestObject) (api.GetVerificationStatusResponseObject, error) {
	s, err := h.svc.Status(ctx, principal(ctx).AccountID)
	if err != nil {
		return nil, err
	}
	return api.GetVerificationStatus200JSONResponse(status(s)), nil
}
