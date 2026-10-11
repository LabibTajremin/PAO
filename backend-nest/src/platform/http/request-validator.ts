import Ajv2020, { type ValidateFunction } from 'ajv/dist/2020';
import addFormats from 'ajv-formats';
import { type OpenApiDocument, type OperationInfo, type SpecParameter } from './spec-routes';

/** The parts of a request that the contract constrains. */
export interface RequestParts {
  path: Record<string, unknown>;
  query: Record<string, unknown>;
  headers: Record<string, unknown>;
  cookies: Record<string, unknown>;
  contentType?: string;
  rawBody?: Buffer;
  bodyError?: string;
  body?: unknown;
}

/** Builds an Ajv (JSON Schema 2020-12) instance that knows every schema of `doc`. */
export function specAjv(doc: OpenApiDocument, coerceTypes: boolean): Ajv2020 {
  const ajv = new Ajv2020({
    strict: false,
    allErrors: false,
    coerceTypes: coerceTypes ? 'array' : false,
    validateFormats: true,
  });
  addFormats(ajv);
  // OpenAPI numeric formats only describe size; JSON Schema has nothing to check.
  for (const format of ['int32', 'int64', 'float', 'double', 'byte', 'binary', 'password']) {
    ajv.addFormat(format, true);
  }
  ajv.addSchema({ ...doc, $id: 'spec' });
  return ajv;
}

/** Copies `schema`, pointing its local `$ref`s at the document added to Ajv as `spec`. */
export function qualifyRefs(schema: unknown): unknown {
  if (Array.isArray(schema)) {
    return schema.map(qualifyRefs);
  }
  if (schema === null || typeof schema !== 'object') {
    return schema;
  }
  return Object.fromEntries(
    Object.entries(schema).map(([k, v]) => [
      k,
      k === '$ref' && typeof v === 'string' && v.startsWith('#/') ? 'spec' + v : qualifyRefs(v),
    ]),
  );
}

const LOCATIONS = [
  ['path', 'path'],
  ['query', 'query'],
  ['header', 'headers'],
  ['cookie', 'cookies'],
] as const;

interface CompiledOperation {
  readonly params: readonly [keyof RequestParts, ValidateFunction][];
  readonly body?: ValidateFunction;
  readonly bodyRequired: boolean;
}

function parameterSchema(params: readonly SpecParameter[], loc: string) {
  const own = params.filter((p) => p.in === loc);
  const key = (p: SpecParameter): string => (loc === 'header' ? p.name.toLowerCase() : p.name);
  return {
    type: 'object',
    properties: Object.fromEntries(own.map((p) => [key(p), qualifyRefs(p.schema ?? {})])),
    required: own.filter((p) => p.required === true).map(key),
  };
}

/**
 * Checks requests against the contract (PRD §9.6): path, query, header and cookie
 * parameters are coerced from strings to their schema types in place; bodies are
 * checked as sent. Validators are compiled on first use per operation.
 */
export class RequestValidator {
  private readonly params: Ajv2020;
  private readonly bodies: Ajv2020;
  private readonly compiled = new Map<string, CompiledOperation>();

  constructor(doc: OpenApiDocument) {
    this.params = specAjv(doc, true);
    this.bodies = specAjv(doc, false);
  }

  /** Returns why `req` breaks the contract of `op`, or undefined when it conforms. */
  check(op: OperationInfo, req: RequestParts): string | undefined {
    const c = this.compile(op);
    for (const [part, validate] of c.params) {
      if (!validate(req[part])) {
        return this.params.errorsText(validate.errors, { dataVar: part });
      }
    }
    return c.body ? this.checkBody(c, c.body, req) : undefined;
  }

  private checkBody(c: CompiledOperation, validate: ValidateFunction, req: RequestParts) {
    if (req.bodyError !== undefined) {
      return `request body has an error: ${req.bodyError}`;
    }
    if (req.rawBody === undefined || req.rawBody.length === 0) {
      return c.bodyRequired
        ? 'request body has an error: value is required but missing'
        : undefined;
    }
    if (!/^application\/json\b/i.test(req.contentType ?? '')) {
      return `header Content-Type has unexpected value: ${JSON.stringify(req.contentType ?? '')}`;
    }
    return validate(req.body)
      ? undefined
      : this.bodies.errorsText(validate.errors, { dataVar: 'body' });
  }

  private compile(op: OperationInfo): CompiledOperation {
    const cached = this.compiled.get(op.pointer);
    if (cached) {
      return cached;
    }
    const params = LOCATIONS.map(
      ([loc, part]) =>
        [part, this.params.compile(parameterSchema(op.parameters, loc))] as [
          keyof RequestParts,
          ValidateFunction,
        ],
    );
    const json = op.requestBody?.content?.['application/json'] as { schema?: unknown } | undefined;
    const body =
      json === undefined
        ? undefined
        : this.bodies.compile(qualifyRefs(json.schema ?? {}) as object);
    const c = { params, body, bodyRequired: op.requestBody?.required === true };
    this.compiled.set(op.pointer, c);
    return c;
  }
}
