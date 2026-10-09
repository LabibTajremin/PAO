package postgres

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

type txRepository struct {
	q      *sqlcdb.Queries
	tx     pgx.Tx
	outbox *outbox.Writer
	clock  clock.Clock
}

func jsonOf(v any) []byte {
	raw, _ := json.Marshal(v)
	return raw
}

func (t *txRepository) SaveCategory(ctx context.Context, c domain.Category) error {
	_, err := t.q.UpsertCategory(ctx, sqlcdb.UpsertCategoryParams{ID: c.ID, NameEn: c.Name.EN, NameBn: c.Name.BN, IconKey: c.IconKey,
		SortOrder: int32(c.SortOrder), Published: c.Published, CreatedAt: t.clock.Now()}) //nolint:gosec // small admin-set ordinal
	return err
}

func (t *txRepository) SaveService(ctx context.Context, s domain.Service) error {
	_, err := t.q.UpsertService(ctx, sqlcdb.UpsertServiceParams{
		ID: s.ID, CategoryID: s.CategoryID, NameEn: s.Name.EN, NameBn: s.Name.BN, IconKey: s.IconKey, ServiceModel: s.Model,
		RequiredLevel: int32(s.RequiredLevel), SearchRadiusM: int32(s.SearchRadiusM), WomenProvidersOnly: s.WomenProvidersOnly, //nolint:gosec // validated ranges
		RequiresLevel2: s.RequiresLevel2, Level2Checklist: jsonOf(orEmpty(s.Level2Checklist)), SortOrder: int32(s.SortOrder), Published: s.Published, //nolint:gosec // small ordinal
		CreatedAt: t.clock.Now(),
	})
	return err
}

func (t *txRepository) SaveSubService(ctx context.Context, s domain.SubService) error {
	_, err := t.q.UpsertSubService(ctx, sqlcdb.UpsertSubServiceParams{
		ID: s.ID, ServiceID: s.ServiceID, NameEn: s.Name.EN, NameBn: s.Name.BN, Description: jsonOf(s.Description),
		Inclusions: jsonOf(orEmpty(s.Inclusions)), Exclusions: jsonOf(orEmpty(s.Exclusions)), Unit: s.Unit,
		MaxQuantity: int32(s.MaxQuantity), SortOrder: int32(s.SortOrder), Published: s.Published, CreatedAt: t.clock.Now(), //nolint:gosec // validated small values
	})
	return err
}

func orEmpty(n []domain.Name) []domain.Name {
	if n == nil {
		return []domain.Name{}
	}
	return n
}

func (t *txRepository) AddPrice(ctx context.Context, p domain.PriceVersion) error {
	return t.q.AddPrice(ctx, sqlcdb.AddPriceParams{ID: p.ID, SubServiceID: p.SubServiceID, AmountPaisa: p.Amount, EffectiveFrom: p.EffectiveFrom, CreatedBy: p.CreatedBy})
}

func (t *txRepository) BumpVersion(ctx context.Context) (int64, error) { return t.q.BumpVersion(ctx) }

func (t *txRepository) Publish(ctx context.Context, aggregateID string, e eventbus.Event) error {
	return t.outbox.Write(ctx, t.tx, aggregateID, e)
}
