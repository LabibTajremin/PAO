// Package http serves the identity operations of api/openapi.yaml: sign-in, tokens,
// the current account and the admin user and role screens.
package http

import (
	"context"
	"fmt"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the identity part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the identity handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

// RequestOtp implements POST /v1/auth/otp/request.
func (h *Handler) RequestOtp(ctx context.Context, req api.RequestOtpRequestObject) (api.RequestOtpResponseObject, error) {
	purpose := app.PurposeLogin
	if req.Body.Purpose != nil {
		purpose = string(*req.Body.Purpose)
	}
	_, err := h.svc.SendCode(ctx, app.SendCodeInput{Phone: req.Body.Phone, Purpose: purpose, ClientIP: httpx.ClientIPFrom(ctx)})
	if err != nil {
		return nil, mapError(err)
	}
	return api.RequestOtp202JSONResponse{
		ExpiresInSeconds: int(domain.CodeTTL.Seconds()), ResendAfterSeconds: int(domain.ResendAfter.Seconds()),
	}, nil
}

// VerifyOtp implements POST /v1/auth/otp/verify.
func (h *Handler) VerifyOtp(ctx context.Context, req api.VerifyOtpRequestObject) (api.VerifyOtpResponseObject, error) {
	s, err := h.svc.VerifyLogin(ctx, app.VerifyLoginInput{Phone: req.Body.Phone, Code: req.Body.Code, App: string(req.Body.App)})
	if err != nil {
		return nil, mapError(err)
	}
	return api.VerifyOtp200JSONResponse(tokenPair(s, true)), nil
}

// RefreshToken implements POST /v1/auth/refresh. Mobile apps send the token in the
// body; the admin web app relies on its HttpOnly cookie and gets the new one back as a
// cookie.
func (h *Handler) RefreshToken(ctx context.Context, req api.RefreshTokenRequestObject) (api.RefreshTokenResponseObject, error) {
	token, fromCookie := "", false
	if req.Body != nil && req.Body.RefreshToken != nil {
		token = *req.Body.RefreshToken
	} else if req.Params.PaoRefresh != nil {
		token, fromCookie = *req.Params.PaoRefresh, true
	}
	s, err := h.svc.Refresh(ctx, token)
	if err != nil {
		return nil, mapError(err)
	}
	resp := api.RefreshToken200JSONResponse{Body: tokenPair(s, !fromCookie)}
	if fromCookie {
		resp.Headers.SetCookie = refreshCookie(s.RefreshToken, domain.RefreshTTL)
	}
	return resp, nil
}

// Logout implements POST /v1/auth/logout.
func (h *Handler) Logout(ctx context.Context, req api.LogoutRequestObject) (api.LogoutResponseObject, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	all := req.Body != nil && req.Body.AllDevices != nil && *req.Body.AllDevices
	if err := h.svc.Logout(ctx, caller(p), all); err != nil {
		return nil, mapError(err)
	}
	resp := api.Logout204Response{}
	if req.Params.PaoRefresh != nil {
		resp.Headers.SetCookie = refreshCookie("", 0)
	}
	return resp, nil
}

// AdminLogin implements POST /v1/auth/admin/login.
func (h *Handler) AdminLogin(ctx context.Context, req api.AdminLoginRequestObject) (api.AdminLoginResponseObject, error) {
	ch, err := h.svc.AdminLogin(ctx, string(req.Body.Email), req.Body.Password)
	if err != nil {
		return nil, mapError(err)
	}
	out := api.AdminLogin200JSONResponse{
		ChallengeId: mustUUID(ch.ID), ExpiresInSeconds: int(domain.ChallengeTTL.Seconds()), MustChangePassword: &ch.MustChangePassword,
	}
	if ch.EnrolSecret != "" {
		out.TotpEnrolment = &api.TotpEnrolment{Secret: ch.EnrolSecret, OtpauthUrl: ch.EnrolURL}
	}
	return out, nil
}

// AdminVerifyTotp implements POST /v1/auth/admin/totp.
func (h *Handler) AdminVerifyTotp(ctx context.Context, req api.AdminVerifyTotpRequestObject) (api.AdminVerifyTotpResponseObject, error) {
	s, err := h.svc.AdminVerifyTOTP(ctx, req.Body.ChallengeId.String(), req.Body.Code)
	if err != nil {
		return nil, mapError(err)
	}
	return api.AdminVerifyTotp200JSONResponse{
		Body:    tokenPair(s, false),
		Headers: api.AdminVerifyTotp200ResponseHeaders{SetCookie: refreshCookie(s.RefreshToken, domain.RefreshTTL)},
	}, nil
}

// ChangeAdminPassword implements POST /v1/auth/admin/password.
func (h *Handler) ChangeAdminPassword(ctx context.Context, req api.ChangeAdminPasswordRequestObject) (api.ChangeAdminPasswordResponseObject, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	if err := h.svc.ChangeAdminPassword(ctx, p.AccountID, req.Body.CurrentPassword, req.Body.NewPassword); err != nil {
		return nil, mapError(err)
	}
	return api.ChangeAdminPassword204Response{}, nil
}

// refreshCookie builds the admin refresh cookie; maxAge 0 clears it.
func refreshCookie(token string, maxAge time.Duration) *string {
	c := fmt.Sprintf("pao_refresh=%s; Path=/v1/auth; Max-Age=%d; HttpOnly; Secure; SameSite=Strict", token, int(maxAge.Seconds()))
	return &c
}

func caller(p httpx.Principal) app.Caller {
	return app.Caller{AccountID: p.AccountID, SessionID: p.SessionID, TokenID: p.TokenID, ExpiresAt: p.ExpiresAt}
}
