package app

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"math"
	"time"

	"github.com/google/uuid"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	providerdomain "github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
)

// PerfFixture is what test/perf scripts need to call the API as customers.
type PerfFixture struct {
	Tokens       []string  `json:"tokens"`
	ServiceID    uuid.UUID `json:"serviceId"`
	SubServiceID uuid.UUID `json:"subServiceId"`
	Lat          float64   `json:"lat"`
	Lng          float64   `json:"lng"`
}

// perfCentre is Banani, Dhaka; seeded providers spread around it.
var perfCentre = providerdomain.Point{Lat: 23.7937, Lng: 90.4066}

// SeedPerf puts n verified electricians online around Dhaka and writes customer tokens
// for the nearby-search smoke test (03-testing.md). Rows are written directly because
// enrolling thousands of providers through the API would dominate the run.
func SeedPerf(ctx context.Context, i *Infra, m *Modules, n int, out io.Writer) error {
	if i.Config.AppEnv == config.EnvProd {
		return errors.New("perf seed refuses to run in production")
	}
	service := catalogapp.SeedID("service", "electrician")
	for k := range n {
		id := uuid.New()
		// A golden-angle spiral spreads providers evenly over about 3 km.
		r, a := 0.03*math.Sqrt(float64(k)/float64(n)), float64(k)*2.39996
		at := providerdomain.Point{Lat: perfCentre.Lat + r*math.Sin(a), Lng: perfCentre.Lng + r*math.Cos(a)}
		_, err := i.Pool.Exec(ctx, `WITH p AS (
			INSERT INTO provider.providers (id, phone, full_name, gender, level, working_radius_m, rating_avg, rating_count,
				home_base, created_at, updated_at)
			VALUES ($1, '', 'Perf Provider', 'male', 1, 30000, 4.5, 10, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, now(), now()))
			INSERT INTO provider.provider_services (provider_id, service_id) VALUES ($1, $2)`, id, service, at.Lng, at.Lat)
		if err == nil {
			_, err = i.Pool.Exec(ctx, `INSERT INTO verification.levels (provider_id, level) VALUES ($1, 1)`, id)
		}
		if err == nil {
			err = m.Provider.Service.GoOnline(ctx, id, at)
		}
		if err != nil {
			return err
		}
	}
	signer := auth.NewSigner(i.Config.JWT.KeyID, i.Config.JWT.SigningKey, 2*time.Hour, i.Clock, i.IDs)
	f := PerfFixture{ServiceID: service, SubServiceID: catalogapp.SeedID("sub-service", "fan-install"), Lat: perfCentre.Lat, Lng: perfCentre.Lng}
	var signErr error
	for range 50 {
		tok, _, err := signer.Sign(auth.Claims{Subject: uuid.New(), Roles: []string{"customer"}, SessionID: uuid.New()})
		f.Tokens, signErr = append(f.Tokens, tok), errors.Join(signErr, err)
	}
	return errors.Join(signErr, json.NewEncoder(out).Encode(f))
}
