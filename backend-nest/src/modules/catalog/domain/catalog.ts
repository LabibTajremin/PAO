// The catalog rules: the Category → Service → Sub-service tree and immutable, versioned
// prices (PRD §4).

/** A text in English and Bangla. */
export interface Name {
  readonly en: string;
  readonly bn: string;
}

/** Service models (PRD §4). */
export const MODELS = [
  'on_demand',
  'duration_hire',
  'listing',
  'partner_referral',
] as readonly string[];

/** What one quantity of a sub-service can mean. */
export const UNITS = ['job', 'unit', 'hour', 'day'] as readonly string[];

/** The bookable item with its current price. */
export interface SubService {
  readonly id: string;
  readonly serviceId: string;
  readonly name: Name;
  readonly description: Name;
  readonly inclusions: readonly Name[];
  readonly exclusions: readonly Name[];
  readonly unit: string;
  readonly maxQuantity: number;
  readonly sortOrder: number;
  readonly published: boolean;
  readonly priceVersionId: string;
  readonly price: number;
}

/** A sub-service as written: its price changes only through a new price version. */
export type SubServiceFields = Omit<SubService, 'priceVersionId' | 'price'>;

/** A trade with the rules other modules enforce. */
export interface Service {
  readonly id: string;
  readonly categoryId: string;
  readonly name: Name;
  readonly iconKey: string;
  readonly model: string;
  readonly requiredLevel: number;
  readonly searchRadiusM: number;
  readonly womenProvidersOnly: boolean;
  readonly requiresLevel2: boolean;
  readonly level2Checklist: readonly Name[];
  readonly sortOrder: number;
  readonly published: boolean;
  readonly subServices: readonly SubService[];
}

/** A service as written, without its sub-services. */
export type ServiceFields = Omit<Service, 'subServices'>;

/** Groups services. */
export interface Category {
  readonly id: string;
  readonly name: Name;
  readonly iconKey: string;
  readonly sortOrder: number;
  readonly published: boolean;
  readonly services: readonly Service[];
}

/** A category as written, without its services. */
export type CategoryFields = Omit<Category, 'services'>;

/** One immutable price row. */
export interface PriceVersion {
  readonly id: string;
  readonly subServiceId: string;
  readonly amount: number;
  readonly effectiveFrom: Date;
  /** The admin who set it; the nil UUID for the seed, which no person runs. */
  readonly createdBy: string;
}

const filled = (s: string): boolean => s.trim() !== '';
const validName = (n: Name): boolean => filled(n.en) && filled(n.bn);

/** Reports whether a category has both names and an icon. */
export function isValidCategory(c: Pick<Category, 'name' | 'iconKey'>): boolean {
  return validName(c.name) && filled(c.iconKey);
}

/** Reports whether a service keeps the catalog rules. */
export function isValidService(s: ServiceFields): boolean {
  const wellFormed =
    validName(s.name) &&
    filled(s.iconKey) &&
    MODELS.includes(s.model) &&
    s.requiredLevel >= 0 &&
    s.requiredLevel <= 2 &&
    s.searchRadiusM >= 500 &&
    s.searchRadiusM <= 50_000;
  // A service that needs Level 2 before the first booking requires level 2 (D7).
  return wellFormed && (!s.requiresLevel2 || s.requiredLevel >= 2);
}

/** Reports whether a sub-service has names, a known unit and a positive maximum. */
export function isValidSubService(s: Pick<SubService, 'name' | 'unit' | 'maxQuantity'>): boolean {
  return validName(s.name) && UNITS.includes(s.unit) && s.maxQuantity >= 1;
}

/** Reports whether an amount in paisa can be a price. */
export function isValidPrice(amount: number): boolean {
  return amount >= 0;
}

/** Keeps only published categories, services and sub-services. */
export function publishedOnly(tree: readonly Category[]): Category[] {
  return tree
    .filter((c) => c.published)
    .map((c) => ({
      ...c,
      services: c.services
        .filter((s) => s.published)
        .map((s) => ({ ...s, subServices: s.subServices.filter((ss) => ss.published) })),
    }));
}

/** Every service of a tree, in tree order. */
export function servicesOf(tree: readonly Category[]): Service[] {
  return tree.flatMap((c) => c.services);
}
