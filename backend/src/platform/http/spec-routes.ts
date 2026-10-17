import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'yaml';
import { PACKAGE_ROOT } from '../paths';

/** An OpenAPI parameter, after `$ref` resolution. */
export interface SpecParameter {
  readonly name: string;
  readonly in: 'path' | 'query' | 'header' | 'cookie';
  readonly required?: boolean;
  readonly schema?: unknown;
}

/** The parts of an OpenAPI operation the HTTP edge reads. */
export interface SpecOperation {
  readonly operationId?: string;
  readonly 'x-permission'?: string;
  readonly parameters?: readonly unknown[];
  readonly requestBody?: unknown;
  readonly responses?: Readonly<Record<string, unknown>>;
}

/** The bundled OpenAPI document (paths and components). */
export interface OpenApiDocument {
  readonly paths: Readonly<Record<string, Readonly<Record<string, unknown>>>>;
  readonly components?: Readonly<Record<string, unknown>>;
}

/** Injection token for the {@link OpenApiDocument} the API serves. */
export const OPENAPI_DOCUMENT = Symbol('OpenApiDocument');

/** Where the bundled contract (`api/openapi.yaml` bundled by `npm run gen`) lives. */
export const OPENAPI_DOCUMENT_PATH = join(PACKAGE_ROOT, 'src/platform/http/openapi.gen.yaml');

/** Reads the bundled OpenAPI document. */
export function loadOpenApiDocument(path: string = OPENAPI_DOCUMENT_PATH): OpenApiDocument {
  return parse(readFileSync(path, 'utf8')) as OpenApiDocument;
}

/** One operation of the contract with everything needed to match and check requests. */
export interface OperationInfo {
  readonly id: string;
  readonly method: string;
  readonly pathTemplate: string;
  /** The `x-permission`; undefined means the spec forgot it and requests are denied. */
  readonly permission?: string;
  /** True when the operation takes an `Idempotency-Key` header. */
  readonly idempotent: boolean;
  readonly parameters: readonly SpecParameter[];
  readonly requestBody?: {
    readonly required?: boolean;
    readonly content?: Record<string, unknown>;
  };
  /** The declared answers by status code (or `default`). */
  readonly responses: Readonly<Record<string, unknown>>;
  /** JSON pointer of the operation inside the document, for schema references. */
  readonly pointer: string;
}

/** An operation matched for a request, with its path parameters as sent. */
export interface MatchedOperation extends OperationInfo {
  readonly pathParams: Readonly<Record<string, string>>;
}

/** The outcome of matching a request against the contract. */
export type RouteMatch = MatchedOperation | 'not_found' | 'method_not_allowed';

const METHODS = ['get', 'put', 'post', 'delete', 'patch', 'options', 'head', 'trace'];

/** Follows a local `$ref` (`#/components/...`) to the object it names. */
export function resolveRef(doc: OpenApiDocument, value: unknown): unknown {
  const ref = (value as { $ref?: unknown } | null)?.$ref;
  if (typeof ref !== 'string' || !ref.startsWith('#/')) {
    return value;
  }
  let node: unknown = doc;
  for (const part of ref.slice(2).split('/')) {
    node = (node as Record<string, unknown> | undefined)?.[decodePointer(part)];
  }
  return resolveRef(doc, node);
}

/** Escapes one segment of a JSON pointer. */
export function encodePointer(part: string): string {
  return part.replaceAll('~', '~0').replaceAll('/', '~1');
}

function decodePointer(part: string): string {
  return part.replaceAll('~1', '/').replaceAll('~0', '~');
}

interface PathEntry {
  readonly template: string;
  readonly pattern: RegExp;
  readonly names: readonly string[];
  readonly operations: ReadonlyMap<string, OperationInfo>;
}

function compileTemplate(template: string): { pattern: RegExp; names: string[] } {
  const names: string[] = [];
  const source = template
    .split(/(\{[^}]+\})/)
    .map((part) => {
      const name = /^\{([^}]+)\}$/.exec(part)?.[1];
      if (name === undefined) {
        return part.replace(/[.*+?^$()|[\]\\]/g, '\\$&');
      }
      names.push(name);
      return '([^/]+)';
    })
    .join('');
  return { pattern: new RegExp(`^${source}$`), names };
}

/**
 * Matches requests to the operations of the contract. Literal paths win over templated
 * ones, so `/v1/admin/providers/queue` is never read as `/v1/admin/providers/{id}`.
 */
export class SpecRoutes {
  private readonly entries: PathEntry[] = [];

  constructor(private readonly doc: OpenApiDocument) {
    for (const [template, item] of Object.entries(doc.paths)) {
      this.entries.push(this.entry(template, item));
    }
    this.entries.sort((a, b) => a.names.length - b.names.length);
  }

  /** Every operation of the contract. */
  operations(): OperationInfo[] {
    return this.entries.flatMap((e) => [...e.operations.values()]);
  }

  /** Finds the operation for `method` and `path` (without the query string). */
  match(method: string, path: string): RouteMatch {
    let found: RouteMatch = 'not_found';
    for (const e of this.entries) {
      const values = e.pattern.exec(path);
      if (!values) {
        continue;
      }
      const op = e.operations.get(method.toLowerCase());
      if (!op) {
        found = 'method_not_allowed';
        continue;
      }
      const pathParams = Object.fromEntries(
        e.names.map((n, i) => [n, safeDecode(values[i + 1] ?? '')]),
      );
      return { ...op, pathParams };
    }
    return found;
  }

  private entry(template: string, item: Readonly<Record<string, unknown>>): PathEntry {
    const { pattern, names } = compileTemplate(template);
    const shared = (item.parameters as unknown[] | undefined) ?? [];
    const operations = new Map<string, OperationInfo>();
    for (const method of METHODS.filter((m) => item[m] !== undefined)) {
      const op = item[method] as SpecOperation;
      const parameters = [...shared, ...(op.parameters ?? [])].map(
        (p) => resolveRef(this.doc, p) as SpecParameter,
      );
      for (const name of names) {
        if (!parameters.some((p) => p.in === 'path' && p.name === name)) {
          throw new Error(`${method} ${template}: path parameter ${name} is not declared`);
        }
      }
      operations.set(method, {
        id: op.operationId ?? `${method} ${template}`,
        method,
        pathTemplate: template,
        permission: op['x-permission'],
        idempotent: parameters.some((p) => p.in === 'header' && p.name === 'Idempotency-Key'),
        parameters,
        requestBody: resolveRef(this.doc, op.requestBody) as OperationInfo['requestBody'],
        responses: op.responses ?? {},
        pointer: `#/paths/${encodePointer(template)}/${method}`,
      });
    }
    return { template, pattern, names, operations };
  }
}

function safeDecode(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}
