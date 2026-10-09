package postgres

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
)

type levelRow = sqlcdb.LockLevelRow

// load reads a provider's state; level comes from the caller so Change can lock it.
func load(ctx context.Context, q *sqlcdb.Queries, id uuid.UUID, lvl levelRow) (domain.State, error) {
	st := domain.NewState(id)
	st.Level, st.Level2PassedAt, st.Blocked, st.ServiceIDs, st.SubmittedAt = int(lvl.Level), lvl.Level2PassedAt, lvl.Blocked, lvl.ServiceIds, lvl.SubmittedAt
	items, err := q.ItemsByProvider(ctx, id)
	for _, r := range items {
		it := domain.Item{Type: r.ItemType, Status: r.Status, Reason: r.RejectionReason, SubmittedAt: r.SubmittedAt,
			DecidedAt: r.DecidedAt, DecidedBy: r.DecidedBy, ExpiresAt: r.ExpiresAt}
		_ = json.Unmarshal(r.Fields, &it.Fields)
		st.Items[r.ItemType] = it
	}
	var sessions []sqlcdb.VerificationLevel2Session
	if err == nil {
		sessions, err = q.SessionsByProvider(ctx, id)
	}
	for _, s := range sessions {
		st.Sessions = append(st.Sessions, toSession(s))
	}
	var docs []sqlcdb.CurrentDocumentsRow
	if err == nil {
		docs, err = q.CurrentDocuments(ctx, id)
	}
	for _, d := range docs {
		st.Documents = append(st.Documents, domain.Document{ID: d.ID, ItemType: d.ItemType, Kind: d.Kind, MediaID: d.MediaID, CreatedAt: d.CreatedAt})
	}
	if err == nil {
		var nid sqlcdb.NIDByProviderRow
		nid, err = q.NIDByProvider(ctx, id)
		if err == nil {
			st.NID = &domain.NIDRecord{Ciphertext: nid.NidCiphertext, Hash: nid.NidHash}
		}
		if errors.Is(err, pgx.ErrNoRows) {
			err = nil
		}
	}
	return st, err
}

func toSession(s sqlcdb.VerificationLevel2Session) domain.Session {
	out := domain.Session{ID: s.ID, ProviderID: s.ProviderID, ServiceID: s.ServiceID, ScheduledAt: s.ScheduledAt, Location: s.Location,
		Status: s.Status, Notes: s.Notes, VisitLat: s.VisitLat, VisitLng: s.VisitLng, Photos: s.PhotoMediaIds,
		DecidedBy: s.DecidedBy, DecidedAt: s.DecidedAt, CreatedAt: s.CreatedAt}
	if s.Result != nil {
		out.Result = *s.Result
	}
	_ = json.Unmarshal(s.Checklist, &out.Checklist)
	return out
}

func jsonOf(v any) []byte {
	raw, _ := json.Marshal(v)
	return raw
}

// save writes the whole state; rows are few per provider, so rewriting them all keeps
// the code free of change tracking.
func save(ctx context.Context, q *sqlcdb.Queries, st domain.State, now time.Time) error {
	err := q.SaveLevel(ctx, sqlcdb.SaveLevelParams{ProviderID: st.ProviderID, Level: int32(st.Level), Level2PassedAt: st.Level2PassedAt, //nolint:gosec // level 0–2
		Blocked: st.Blocked, ServiceIds: orEmpty(st.ServiceIDs), SubmittedAt: st.SubmittedAt, UpdatedAt: now})
	for t, it := range st.Items {
		if err == nil {
			err = q.UpsertItem(ctx, sqlcdb.UpsertItemParams{ProviderID: st.ProviderID, ItemType: t, Status: it.Status, RejectionReason: it.Reason,
				Fields: jsonOf(it.Fields), SubmittedAt: it.SubmittedAt, DecidedAt: it.DecidedAt, DecidedBy: it.DecidedBy, ExpiresAt: it.ExpiresAt})
		}
	}
	if err == nil {
		err = saveDocuments(ctx, q, st, now)
	}
	for _, s := range st.Sessions {
		if err == nil {
			err = q.UpsertSession(ctx, sessionParams(s))
		}
	}
	return err
}

func saveDocuments(ctx context.Context, q *sqlcdb.Queries, st domain.State, now time.Time) error {
	types := []string{}
	for _, d := range st.NewDocuments {
		types = append(types, d.ItemType)
	}
	err := q.RetireDocuments(ctx, sqlcdb.RetireDocumentsParams{ProviderID: st.ProviderID, ItemTypes: types})
	for _, d := range st.NewDocuments {
		if err == nil {
			err = q.InsertDocument(ctx, sqlcdb.InsertDocumentParams{ID: d.ID, ProviderID: st.ProviderID, ItemType: d.ItemType, Kind: d.Kind,
				MediaID: d.MediaID, CreatedAt: d.CreatedAt})
		}
	}
	if err == nil && st.NIDChanged {
		err = q.UpsertNID(ctx, sqlcdb.UpsertNIDParams{ProviderID: st.ProviderID, NidCiphertext: st.NID.Ciphertext, NidHash: st.NID.Hash, UpdatedAt: now})
	}
	return err
}

func sessionParams(s domain.Session) sqlcdb.UpsertSessionParams {
	p := sqlcdb.UpsertSessionParams{ID: s.ID, ProviderID: s.ProviderID, ServiceID: s.ServiceID, ScheduledAt: s.ScheduledAt, Location: s.Location,
		Status: s.Status, Checklist: jsonOf(s.Checklist), Notes: s.Notes, VisitLat: s.VisitLat, VisitLng: s.VisitLng,
		PhotoMediaIds: orEmpty(s.Photos), DecidedBy: s.DecidedBy, DecidedAt: s.DecidedAt, CreatedAt: s.CreatedAt}
	if s.Result != "" {
		p.Result = &s.Result
	}
	return p
}

func orEmpty(ids []uuid.UUID) []uuid.UUID {
	if ids == nil {
		return []uuid.UUID{}
	}
	return ids
}
