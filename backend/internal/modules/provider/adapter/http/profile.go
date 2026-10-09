package http

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func toProfile(p app.Profile) api.ProviderProfile {
	out := api.ProviderProfile{Id: p.ID, Name: p.FullName, Phone: p.Phone, Status: api.AccountStatus(p.AccountStatus), Level: p.Level,
		Badge: api.Badge(domain.Badge(p.Level)), Online: p.Online, Language: api.Language(p.Language), ExperienceYears: p.ExperienceYears,
		Bio: &p.Bio, FlaggedForReview: &p.Flagged, Services: []api.ServiceRef{}}
	if p.PhotoURL != "" {
		out.PhotoUrl = &p.PhotoURL
	}
	if p.HomeBase != nil {
		out.HomeBase, out.WorkingRadiusM = &api.Point{Lat: p.HomeBase.Lat, Lng: p.HomeBase.Lng}, &p.WorkingRadiusM
	}
	for _, s := range p.Services {
		out.Services = append(out.Services, api.ServiceRef{Id: s.ID, Name: api.LocalizedText{En: s.Name.EN, Bn: s.Name.BN}})
	}
	return out
}

// GetProviderProfile implements GET /v1/provider/profile.
func (h *Handler) GetProviderProfile(ctx context.Context, _ api.GetProviderProfileRequestObject) (api.GetProviderProfileResponseObject, error) {
	p, err := h.svc.Profile(ctx, me(ctx))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetProviderProfile200JSONResponse(toProfile(p)), nil
}

// UpdateProviderProfile implements PUT /v1/provider/profile.
func (h *Handler) UpdateProviderProfile(ctx context.Context, req api.UpdateProviderProfileRequestObject) (api.UpdateProviderProfileResponseObject, error) {
	bio := ""
	if req.Body.Bio != nil {
		bio = *req.Body.Bio
	}
	p, err := h.svc.UpdateProfile(ctx, me(ctx), bio, req.Body.PhotoMediaId, string(req.Body.Language))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.UpdateProviderProfile200JSONResponse(toProfile(p)), nil
}

func presence(online bool) api.PresenceState {
	every := app.HeartbeatEvery
	return api.PresenceState{Online: online, HeartbeatIntervalSeconds: &every}
}

// GoOnline implements POST /v1/provider/presence/online.
func (h *Handler) GoOnline(ctx context.Context, req api.GoOnlineRequestObject) (api.GoOnlineResponseObject, error) {
	at := domain.Point{Lat: req.Body.Location.Lat, Lng: req.Body.Location.Lng}
	if err := h.svc.GoOnline(ctx, me(ctx), at); err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GoOnline200JSONResponse(presence(true)), nil
}

// GoOffline implements POST /v1/provider/presence/offline.
func (h *Handler) GoOffline(ctx context.Context, _ api.GoOfflineRequestObject) (api.GoOfflineResponseObject, error) {
	if err := h.svc.GoOffline(ctx, me(ctx), "provider"); err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GoOffline200JSONResponse(presence(false)), nil
}

// SendHeartbeat implements POST /v1/provider/presence/heartbeat.
func (h *Handler) SendHeartbeat(ctx context.Context, req api.SendHeartbeatRequestObject) (api.SendHeartbeatResponseObject, error) {
	at := domain.Point{Lat: req.Body.Location.Lat, Lng: req.Body.Location.Lng}
	if err := h.svc.Heartbeat(ctx, me(ctx), at); err != nil {
		return nil, errorMap.Map(err)
	}
	return api.SendHeartbeat200JSONResponse(presence(true)), nil
}
