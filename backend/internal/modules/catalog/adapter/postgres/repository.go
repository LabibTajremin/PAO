// Package postgres implements the catalog repository on the catalog schema.
package postgres

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Repository is the catalog repository.
type Repository struct {
	pool   *pgxpool.Pool
	q      *sqlcdb.Queries
	outbox *outbox.Writer
	clock  clock.Clock
}

// New returns the repository.
func New(pool *pgxpool.Pool, w *outbox.Writer, clk clock.Clock) *Repository {
	return &Repository{pool: pool, q: sqlcdb.New(pool), outbox: w, clock: clk}
}

func notFound(err error) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.ErrNotFound
	}
	return err
}

// Tree implements port.Repository: three queries assembled in memory.
func (r *Repository) Tree(ctx context.Context) ([]domain.Category, error) {
	cats, err := r.q.Categories(ctx)
	if err != nil {
		return nil, err
	}
	services, err := r.q.Services(ctx)
	if err != nil {
		return nil, err
	}
	subs, err := r.q.SubServices(ctx)
	if err != nil {
		return nil, err
	}
	subsByService := map[uuid.UUID][]domain.SubService{}
	for _, s := range subs {
		subsByService[s.ServiceID] = append(subsByService[s.ServiceID], toSubService(sqlcdb.SubServiceByIDRow(s)))
	}
	servicesByCat := map[uuid.UUID][]domain.Service{}
	for _, s := range services {
		svc := toService(sqlcdb.ServiceByIDRow(s))
		svc.SubServices = subsByService[svc.ID]
		servicesByCat[svc.CategoryID] = append(servicesByCat[svc.CategoryID], svc)
	}
	out := make([]domain.Category, 0, len(cats))
	for _, c := range cats {
		out = append(out, domain.Category{ID: c.ID, Name: domain.Name{EN: c.NameEn, BN: c.NameBn}, IconKey: c.IconKey,
			SortOrder: int(c.SortOrder), Published: c.Published, Services: servicesByCat[c.ID]})
	}
	return out, nil
}

// CategoryExists implements port.Repository.
func (r *Repository) CategoryExists(ctx context.Context, id uuid.UUID) (bool, error) {
	return r.q.CategoryExists(ctx, id)
}

// Service implements port.Repository.
func (r *Repository) Service(ctx context.Context, id uuid.UUID) (domain.Service, error) {
	row, err := r.q.ServiceByID(ctx, id)
	if err != nil {
		return domain.Service{}, notFound(err)
	}
	subs, err := r.q.SubServicesOfService(ctx, id)
	svc := toService(row)
	for _, s := range subs {
		svc.SubServices = append(svc.SubServices, toSubService(sqlcdb.SubServiceByIDRow(s)))
	}
	return svc, err
}

// SubService implements port.Repository.
func (r *Repository) SubService(ctx context.Context, id uuid.UUID) (domain.SubService, error) {
	row, err := r.q.SubServiceByID(ctx, id)
	return toSubService(row), notFound(err)
}

// PriceHistory implements port.Repository.
func (r *Repository) PriceHistory(ctx context.Context, id uuid.UUID) ([]domain.PriceVersion, error) {
	rows, err := r.q.PriceHistory(ctx, id)
	out := make([]domain.PriceVersion, 0, len(rows))
	for _, p := range rows {
		out = append(out, domain.PriceVersion{ID: p.ID, SubServiceID: p.SubServiceID, Amount: p.AmountPaisa, EffectiveFrom: p.EffectiveFrom, CreatedBy: p.CreatedBy})
	}
	return out, err
}

// Search implements port.Repository.
func (r *Repository) Search(ctx context.Context, q string) ([]uuid.UUID, []uuid.UUID, error) {
	services, err := r.q.SearchServices(ctx, q)
	if err != nil {
		return nil, nil, err
	}
	subs, err := r.q.SearchSubServices(ctx, q)
	return services, subs, err
}

// Version implements port.Repository.
func (r *Repository) Version(ctx context.Context) (int64, error) { return r.q.Version(ctx) }

// InTx implements port.Repository.
func (r *Repository) InTx(ctx context.Context, fn func(tx port.TxRepository) error) error {
	return db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		return fn(&txRepository{q: r.q.WithTx(tx), tx: tx, outbox: r.outbox, clock: r.clock})
	})
}

func toService(s sqlcdb.ServiceByIDRow) domain.Service {
	svc := domain.Service{ID: s.ID, CategoryID: s.CategoryID, Name: domain.Name{EN: s.NameEn, BN: s.NameBn}, IconKey: s.IconKey,
		Model: s.ServiceModel, RequiredLevel: int(s.RequiredLevel), SearchRadiusM: int(s.SearchRadiusM),
		WomenProvidersOnly: s.WomenProvidersOnly, RequiresLevel2: s.RequiresLevel2, SortOrder: int(s.SortOrder), Published: s.Published,
		Level2Checklist: []domain.Name{}}
	_ = json.Unmarshal(s.Level2Checklist, &svc.Level2Checklist)
	return svc
}

func toSubService(s sqlcdb.SubServiceByIDRow) domain.SubService {
	sub := domain.SubService{ID: s.ID, ServiceID: s.ServiceID, Name: domain.Name{EN: s.NameEn, BN: s.NameBn}, Unit: s.Unit,
		MaxQuantity: int(s.MaxQuantity), SortOrder: int(s.SortOrder), Published: s.Published, PriceVersionID: s.PriceVersionID,
		Price: s.AmountPaisa, Inclusions: []domain.Name{}, Exclusions: []domain.Name{}}
	_ = json.Unmarshal(s.Description, &sub.Description)
	_ = json.Unmarshal(s.Inclusions, &sub.Inclusions)
	_ = json.Unmarshal(s.Exclusions, &sub.Exclusions)
	return sub
}
