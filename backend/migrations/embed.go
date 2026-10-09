// Package migrations embeds the per-module goose SQL migrations so binaries and tests
// apply exactly the files in this folder.
package migrations

import "embed"

// FS holds every module folder of SQL migrations.
//
//go:embed */*.sql
var FS embed.FS

// Modules lists the module folders in the order they are applied. Modules share no
// foreign keys (PRD §9.3 rule 3), so the order only matters for readability.
var Modules = []string{
	"identity", "customer", "provider", "verification", "catalog", "booking",
	"rating", "notification", "media", "admin", "audit",
}

// OutboxModules are the modules that publish events and so own an outbox table; audit
// and notification only consume.
var OutboxModules = []string{
	"identity", "customer", "provider", "verification", "catalog", "booking", "rating", "media", "admin",
}
