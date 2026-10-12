// Checks API responses against the contract, so integration specs catch a controller
// that answers something the apps do not expect.
import { type ValidateFunction } from 'ajv/dist/2020';
import { qualifyRefs, specAjv } from '../../src/platform/http/request-validator';
import { type OpenApiDocument, resolveRef, SpecRoutes } from '../../src/platform/http/spec-routes';

const ERROR_SCHEMA = { $ref: '#/components/schemas/ErrorResponse' };

/** Validates response bodies of the operations in `doc`. */
export class ResponseValidator {
  private readonly ajv;
  private readonly routes: SpecRoutes;
  private readonly compiled = new Map<object, ValidateFunction>();

  constructor(private readonly doc: OpenApiDocument) {
    this.ajv = specAjv(doc, false);
    this.routes = new SpecRoutes(doc);
  }

  /**
   * Returns why the answer breaks the contract, or undefined. An undeclared success
   * status is a break; an undeclared error must still be an ErrorResponse.
   */
  check(method: string, path: string, status: number, body: unknown): string | undefined {
    const op = this.routes.match(method, path.split('?')[0] ?? path);
    if (typeof op === 'string') {
      return undefined;
    }
    const declared = op.responses[String(status)] ?? op.responses.default;
    let schema: unknown = ERROR_SCHEMA;
    if (declared !== undefined) {
      const content = (resolveRef(this.doc, declared) as { content?: Record<string, unknown> })
        .content;
      schema = (content?.['application/json'] as { schema?: unknown } | undefined)?.schema;
    } else if (status < 400) {
      return `${method} ${path}: status ${status} is not in the contract`;
    }
    if (schema === undefined) {
      return undefined;
    }
    const validate = this.validator(schema as object);
    return validate(body)
      ? undefined
      : `${method} ${path} ${status}: ${this.ajv.errorsText(validate.errors, { dataVar: 'body' })}`;
  }

  private validator(schema: object): ValidateFunction {
    let validate = this.compiled.get(schema);
    if (!validate) {
      validate = this.ajv.compile(qualifyRefs(schema) as object);
      this.compiled.set(schema, validate);
    }
    return validate;
  }
}
