// Package redis keeps provider presence in Redis: a GEO set per service and a
// heartbeat key per provider. Positions live only here and vanish on going offline
// (PRD §11).
package redis

import (
	"context"
	"time"

	"github.com/google/uuid"
	goredis "github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// HeartbeatTTL is three missed 30-second heartbeats.
const HeartbeatTTL = 90 * time.Second

// Presence implements port.Presence.
type Presence struct {
	rdb  goredis.Cmdable
	keys redisx.Keys
}

// New returns the presence store.
func New(rdb goredis.Cmdable, keys redisx.Keys) *Presence { return &Presence{rdb: rdb, keys: keys} }

func (p *Presence) geoKey(service uuid.UUID) string {
	return p.keys.Key("presence", "svc", service.String())
}
func (p *Presence) beatKey(id uuid.UUID) string { return p.keys.Key("presence", "hb", id.String()) }
func (p *Presence) onlineKey() string           { return p.keys.Key("presence", "online") }

func (p *Presence) place(ctx context.Context, pipe goredis.Pipeliner, id uuid.UUID, services []uuid.UUID, at domain.Point) {
	for _, s := range services {
		pipe.GeoAdd(ctx, p.geoKey(s), &goredis.GeoLocation{Name: id.String(), Longitude: at.Lng, Latitude: at.Lat})
	}
	pipe.Set(ctx, p.beatKey(id), "1", HeartbeatTTL)
	pipe.SAdd(ctx, p.onlineKey(), id.String())
}

// Online implements port.Presence.
func (p *Presence) Online(ctx context.Context, id uuid.UUID, services []uuid.UUID, at domain.Point) error {
	_, err := p.rdb.TxPipelined(ctx, func(pipe goredis.Pipeliner) error {
		p.place(ctx, pipe, id, services, at)
		return nil
	})
	return err
}

// Beat implements port.Presence.
func (p *Presence) Beat(ctx context.Context, id uuid.UUID, services []uuid.UUID, at domain.Point) error {
	online, err := p.rdb.SIsMember(ctx, p.onlineKey(), id.String()).Result()
	if err == nil && !online {
		err = domain.ErrOffline
	}
	if err != nil {
		return err
	}
	return p.Online(ctx, id, services, at)
}

// Offline implements port.Presence.
func (p *Presence) Offline(ctx context.Context, id uuid.UUID, services []uuid.UUID) error {
	_, err := p.rdb.TxPipelined(ctx, func(pipe goredis.Pipeliner) error {
		for _, s := range services {
			pipe.ZRem(ctx, p.geoKey(s), id.String())
		}
		pipe.Del(ctx, p.beatKey(id))
		pipe.SRem(ctx, p.onlineKey(), id.String())
		return nil
	})
	return err
}

// IsOnline implements port.Presence.
func (p *Presence) IsOnline(ctx context.Context, id uuid.UUID) (bool, error) {
	n, err := p.rdb.Exists(ctx, p.beatKey(id)).Result()
	return n == 1, err
}

// Near implements port.Presence. Members whose heartbeat lapsed are skipped even
// before the reaper removes them.
func (p *Presence) Near(ctx context.Context, service uuid.UUID, at domain.Point, radiusM int) ([]port.Hit, error) {
	locs, err := p.rdb.GeoSearchLocation(ctx, p.geoKey(service), &goredis.GeoSearchLocationQuery{
		GeoSearchQuery: goredis.GeoSearchQuery{Longitude: at.Lng, Latitude: at.Lat, Radius: float64(radiusM), RadiusUnit: "m", Sort: "ASC", Count: 200},
		WithDist:       true,
	}).Result()
	hits := make([]port.Hit, 0, len(locs))
	for _, l := range locs {
		id, _ := uuid.Parse(l.Name)
		if ok, _ := p.IsOnline(ctx, id); ok {
			hits = append(hits, port.Hit{ID: id, DistanceM: int(l.Dist)})
		}
	}
	return hits, err
}

// Lost implements port.Presence.
func (p *Presence) Lost(ctx context.Context) ([]uuid.UUID, error) {
	members, err := p.rdb.SMembers(ctx, p.onlineKey()).Result()
	lost := []uuid.UUID{}
	for _, m := range members {
		id, _ := uuid.Parse(m)
		if ok, _ := p.IsOnline(ctx, id); !ok {
			lost = append(lost, id)
		}
	}
	return lost, err
}
