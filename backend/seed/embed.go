// Package seed embeds the seed data files loaded by `migrate seed` (./pao seed).
package seed

import _ "embed"

// Catalog is catalog.yaml: the MVP services, sub-services and prices, plus demo admins.
//
//go:embed catalog.yaml
var Catalog []byte
