package db

import (
	"context"
	"database/sql"
	"fmt"
	"io/fs"

	"github.com/pressly/goose/v3"
)

// Migrator applies the per-module migrations. Each module keeps its own goose version
// table, so a module's schema can later move to its own database unchanged.
type Migrator struct {
	db      *sql.DB
	fsys    fs.FS
	modules []string
}

// NewMigrator returns a migrator for the module folders in fsys.
func NewMigrator(db *sql.DB, fsys fs.FS, modules []string) *Migrator {
	return &Migrator{db: db, fsys: fsys, modules: modules}
}

// Up applies every pending migration of every module.
func (m *Migrator) Up(ctx context.Context) error {
	for _, module := range m.modules {
		p, err := m.provider(module)
		if err != nil {
			return err
		}
		if _, err := p.Up(ctx); err != nil {
			return fmt.Errorf("migrate %s up: %w", module, err)
		}
	}
	return nil
}

// Down rolls every module back to version zero, in reverse order.
func (m *Migrator) Down(ctx context.Context) error {
	for i := len(m.modules) - 1; i >= 0; i-- {
		p, err := m.provider(m.modules[i])
		if err != nil {
			return err
		}
		if _, err := p.DownTo(ctx, 0); err != nil {
			return fmt.Errorf("migrate %s down: %w", m.modules[i], err)
		}
	}
	return nil
}

func (m *Migrator) provider(module string) (*goose.Provider, error) {
	sub, err := fs.Sub(m.fsys, module)
	if err != nil {
		return nil, fmt.Errorf("migrations for %s: %w", module, err)
	}
	store, err := goose.NewProvider(goose.DialectPostgres, m.db, sub,
		goose.WithTableName("goose_"+module), goose.WithDisableGlobalRegistry(true))
	if err != nil {
		return nil, fmt.Errorf("goose provider for %s: %w", module, err)
	}
	return store, nil
}
