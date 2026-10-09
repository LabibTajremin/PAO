package http

import (
	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func text(n domain.Name) api.LocalizedText { return api.LocalizedText{En: n.EN, Bn: n.BN} }

func name(t api.LocalizedText) domain.Name { return domain.Name{EN: t.En, BN: t.Bn} }

func texts(in []domain.Name) *[]api.LocalizedText {
	out := make([]api.LocalizedText, len(in))
	for i, n := range in {
		out[i] = text(n)
	}
	return &out
}

func names(in *[]api.LocalizedText) []domain.Name {
	if in == nil {
		return []domain.Name{}
	}
	out := make([]domain.Name, len(*in))
	for i, t := range *in {
		out[i] = name(t)
	}
	return out
}

func tree(t app.Tree) api.CatalogTree {
	out := api.CatalogTree{Version: t.Version, Categories: []api.Category{}}
	for _, c := range t.Categories {
		out.Categories = append(out.Categories, category(c))
	}
	return out
}

func category(c domain.Category) api.Category {
	out := api.Category{Id: c.ID, Name: text(c.Name), IconKey: c.IconKey, SortOrder: c.SortOrder, Published: c.Published, Services: []api.Service{}}
	for _, s := range c.Services {
		out.Services = append(out.Services, service(s))
	}
	return out
}

func service(s domain.Service) api.Service {
	subs := make([]api.SubService, 0, len(s.SubServices))
	for _, ss := range s.SubServices {
		subs = append(subs, subService(ss))
	}
	return api.Service{
		Id: s.ID, CategoryId: s.CategoryID, Name: text(s.Name), IconKey: s.IconKey, ServiceModel: api.ServiceModel(s.Model),
		RequiredLevel: s.RequiredLevel, SearchRadiusM: s.SearchRadiusM, WomenProvidersOnly: s.WomenProvidersOnly,
		RequiresLevel2: s.RequiresLevel2, Level2Checklist: texts(s.Level2Checklist), Published: s.Published, SubServices: &subs,
	}
}

func subService(s domain.SubService) api.SubService {
	d := text(s.Description)
	return api.SubService{
		Id: s.ID, ServiceId: s.ServiceID, Name: text(s.Name), Description: &d, Inclusions: texts(s.Inclusions),
		Exclusions: texts(s.Exclusions), Unit: api.PriceUnit(s.Unit), Price: s.Price, PriceVersionId: s.PriceVersionID,
		MaxQuantity: &s.MaxQuantity, Published: s.Published,
	}
}

func price(p domain.PriceVersion) api.PriceVersion {
	return api.PriceVersion{Id: p.ID, SubServiceId: p.SubServiceID, Amount: p.Amount, EffectiveFrom: p.EffectiveFrom, CreatedBy: p.CreatedBy}
}

func flag(b *bool) bool { return b != nil && *b }

func intOr(i *int, fallback int) int {
	if i == nil {
		return fallback
	}
	return *i
}

func categoryInput(id uuid.UUID, in api.CategoryInput) domain.Category {
	return domain.Category{ID: id, Name: name(in.Name), IconKey: in.IconKey, SortOrder: intOr(in.SortOrder, 0), Published: flag(in.Published)}
}

func serviceInput(id uuid.UUID, in api.ServiceInput) domain.Service {
	return domain.Service{
		ID: id, CategoryID: in.CategoryId, Name: name(in.Name), IconKey: in.IconKey, Model: string(in.ServiceModel),
		RequiredLevel: in.RequiredLevel, SearchRadiusM: in.SearchRadiusM, WomenProvidersOnly: flag(in.WomenProvidersOnly),
		RequiresLevel2: flag(in.RequiresLevel2), Level2Checklist: names(in.Level2Checklist), Published: flag(in.Published),
	}
}

func subServiceInput(id uuid.UUID, in api.SubServiceInput) domain.SubService {
	var description domain.Name
	if in.Description != nil {
		description = name(*in.Description)
	}
	return domain.SubService{
		ID: id, ServiceID: in.ServiceId, Name: name(in.Name), Description: description, Inclusions: names(in.Inclusions),
		Exclusions: names(in.Exclusions), Unit: string(in.Unit), MaxQuantity: intOr(in.MaxQuantity, 1), Published: flag(in.Published),
	}
}
