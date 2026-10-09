package outbox

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// TxHandler processes an event inside the subscriber module's transaction.
type TxHandler func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error

// Idempotent wraps h so each event is applied once per handler: the processed-event
// row and h's writes commit together, and a redelivered event is skipped.
func Idempotent(conn db.Beginner, module, handlerName string, h TxHandler) (eventbus.Handler, error) {
	tbl, err := table(module, "processed_events")
	if err != nil {
		return nil, err
	}
	return func(ctx context.Context, env eventbus.Envelope) error {
		return db.WithTx(ctx, conn, func(tx pgx.Tx) error {
			tag, err := tx.Exec(ctx, "INSERT INTO "+tbl+" (handler, event_id) VALUES ($1, $2) ON CONFLICT DO NOTHING", handlerName, env.ID)
			if err != nil {
				return fmt.Errorf("mark %s processed by %s: %w", env.ID, handlerName, err)
			}
			if tag.RowsAffected() == 0 {
				return nil
			}
			return h(ctx, tx, env)
		})
	}, nil
}
