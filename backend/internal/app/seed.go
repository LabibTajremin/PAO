package app

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"gopkg.in/yaml.v3"

	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	identityapp "github.com/LabibTajremin/PAO/backend/internal/modules/identity/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
)

type seedName struct {
	EN string `yaml:"en"`
	BN string `yaml:"bn"`
}

type seedFile struct {
	Categories []struct {
		Key      string   `yaml:"key"`
		Name     seedName `yaml:"name"`
		Icon     string   `yaml:"icon"`
		Services []struct {
			Key           string     `yaml:"key"`
			Name          seedName   `yaml:"name"`
			Icon          string     `yaml:"icon"`
			Model         string     `yaml:"model"`
			RequiredLevel int        `yaml:"required_level"`
			SearchRadiusM int        `yaml:"search_radius_m"`
			WomenOnly     bool       `yaml:"women_providers_only"`
			Level2        bool       `yaml:"requires_level_2"`
			Checklist     []seedName `yaml:"level2_checklist"`
			SubServices   []struct {
				Key         string   `yaml:"key"`
				Name        seedName `yaml:"name"`
				Unit        string   `yaml:"unit"`
				Price       int64    `yaml:"price"`
				MaxQuantity int      `yaml:"max_quantity"`
			} `yaml:"sub_services"`
		} `yaml:"services"`
	} `yaml:"categories"`
	Admins []struct {
		Email string   `yaml:"email"`
		Name  string   `yaml:"name"`
		Roles []string `yaml:"roles"`
	} `yaml:"admins"`
}

// Seed loads the catalog and, outside production, the demo admin users (P04 task 3).
// It is idempotent.
func Seed(ctx context.Context, m *Modules, cfg config.Config, raw []byte) error {
	var f seedFile
	if err := yaml.Unmarshal(raw, &f); err != nil {
		return fmt.Errorf("parse seed: %w", err)
	}
	if err := m.Catalog.Service.Seed(ctx, catalogSeed(f), uuid.Nil); err != nil {
		return fmt.Errorf("seed catalog: %w", err)
	}
	if cfg.AppEnv == config.EnvProd || cfg.SeedAdminPassword == "" {
		return nil
	}
	for _, a := range f.Admins {
		in := identityapp.CreateAdminInput{Email: a.Email, Name: a.Name, Roles: a.Roles}
		if err := m.Identity.Service.EnsureAdmin(ctx, in, cfg.SeedAdminPassword); err != nil {
			return fmt.Errorf("seed admin %s: %w", a.Email, err)
		}
	}
	return nil
}

func catalogSeed(f seedFile) []catalogapp.SeedCategory {
	var cats []catalogapp.SeedCategory
	for _, c := range f.Categories {
		cat := catalogapp.SeedCategory{Key: c.Key, Item: domain.Category{Name: domain.Name(c.Name), IconKey: c.Icon}}
		for _, s := range c.Services {
			svc := catalogapp.SeedService{Key: s.Key, Item: domain.Service{
				Name: domain.Name(s.Name), IconKey: s.Icon, Model: s.Model, RequiredLevel: s.RequiredLevel,
				SearchRadiusM: s.SearchRadiusM, WomenProvidersOnly: s.WomenOnly, RequiresLevel2: s.Level2,
			}}
			for _, n := range s.Checklist {
				svc.Item.Level2Checklist = append(svc.Item.Level2Checklist, domain.Name(n))
			}
			for _, ss := range s.SubServices {
				svc.SubServices = append(svc.SubServices, catalogapp.SeedSubService{Key: ss.Key, Price: ss.Price * 100,
					Item: domain.SubService{Name: domain.Name(ss.Name), Unit: ss.Unit, MaxQuantity: ss.MaxQuantity}})
			}
			cat.Services = append(cat.Services, svc)
		}
		cats = append(cats, cat)
	}
	return cats
}
