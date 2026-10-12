import { NOT_FOUND, VALIDATION_FAILED } from '../../../../platform/http/api-error';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { CatalogReason } from '../../domain/errors';

/** Catalog failures as API errors, as the Go API answered them. */
export const catalogErrors: ErrorMap = {
  [CatalogReason.NotFound]: NOT_FOUND,
  [CatalogReason.Invalid]: VALIDATION_FAILED,
  [CatalogReason.PriceNegative]: VALIDATION_FAILED.withDetails({ field: 'amount' }),
};
