// Guards that hold the backend to the contract the apps were built against.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { bundle, createConfig } from '@redocly/openapi-core';
import {
  loadOpenApiDocument,
  type OpenApiDocument,
  OPENAPI_DOCUMENT_PATH,
  resolveRef,
} from '../platform/http/spec-routes';
import { PACKAGE_ROOT } from '../platform/paths';

const doc = loadOpenApiDocument();

function sourceFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) {
      return name === 'sqlc' ? [] : sourceFiles(path);
    }
    return /(?<!\.spec|\.int-spec)\.ts$/.test(name) ? [path] : [];
  });
}

describe('the bundled contract', () => {
  it('matches a fresh bundle of api/openapi.yaml', async () => {
    const config = await createConfig({});
    const fresh = await bundle({ ref: join(PACKAGE_ROOT, '../api/openapi.yaml'), config });
    expect(JSON.parse(JSON.stringify(fresh.bundle.parsed))).toEqual(doc);
    expect(OPENAPI_DOCUMENT_PATH.startsWith(PACKAGE_ROOT)).toBe(true);
  });
});

describe('error codes', () => {
  it('are all in the ErrorCode enum the apps translate (04-decisions E11)', () => {
    const schemas = doc.components?.schemas as Record<string, { enum: string[] }>;
    const known = new Set(schemas.ErrorCode?.enum);
    const used: string[] = [];
    for (const file of sourceFiles(join(PACKAGE_ROOT, 'src'))) {
      const src = readFileSync(file, 'utf8');
      for (const m of src.matchAll(
        /new ApiError\(\s*\d+,\s*'([A-Z0-9_]+)'|rateLimited\('([A-Z0-9_]+)'/g,
      )) {
        used.push(m[1] ?? m[2] ?? '');
      }
    }
    expect(used.length).toBeGreaterThanOrEqual(10);
    expect(used.filter((code) => !known.has(code))).toEqual([]);
  });
});

// Verification and contact fields that must never reach customers (PRD §6.6, §11).
const SENSITIVE = [
  'nidNumber',
  'documents',
  'faceMatch',
  'selfie',
  'policeClearance',
  'emergencyContact',
  'dateOfBirth',
  'permanentAddress',
];

function propertyNames(d: OpenApiDocument, schema: unknown, seen: Set<unknown>, out: Set<string>) {
  const s = resolveRef(d, schema) as Record<string, unknown> | undefined;
  if (!s || typeof s !== 'object' || seen.has(s)) {
    return;
  }
  seen.add(s);
  for (const [name, prop] of Object.entries((s.properties ?? {}) as Record<string, unknown>)) {
    out.add(name);
    propertyNames(d, prop, seen, out);
  }
  const nested = [s.items, s.additionalProperties, ...((s.allOf ?? []) as unknown[])];
  for (const sub of [
    ...nested,
    ...((s.oneOf ?? []) as unknown[]),
    ...((s.anyOf ?? []) as unknown[]),
  ]) {
    propertyNames(d, sub, seen, out);
  }
}

function responseProperties(responses: Record<string, unknown>): Set<string> {
  const names = new Set<string>();
  for (const response of Object.values(responses)) {
    const resolved = resolveRef(doc, response) as {
      content?: Record<string, { schema?: unknown }>;
    };
    for (const media of Object.values(resolved.content ?? {})) {
      propertyNames(doc, media.schema, new Set(), names);
    }
  }
  return names;
}

describe('customer responses', () => {
  it('never expose verification data', () => {
    let checked = 0;
    for (const [path, item] of Object.entries(doc.paths)) {
      if (!path.startsWith('/v1/customer/') && !path.startsWith('/v1/catalog')) {
        continue;
      }
      for (const op of Object.values(item) as { responses?: Record<string, unknown> }[]) {
        const names = responseProperties(op.responses ?? {});
        expect(`${path}: ${SENSITIVE.filter((f) => names.has(f)).join(',')}`).toBe(`${path}: `);
        checked++;
      }
    }
    expect(checked).toBeGreaterThanOrEqual(10);
  });
});
