// PRD §6.6: verification documents never reach a customer-facing API; customers see
// the badge only. Checked on the contract, so a new customer schema that pulls in a
// document fails here before any code serves it.
import { loadOpenApiDocument } from '../platform/http/spec-routes';

type Node = Readonly<Record<string, unknown>>;

const doc = loadOpenApiDocument();
const schemas = (doc.components?.schemas ?? {}) as Readonly<Record<string, Node>>;

// The schemas that carry verification documents or their review.
const DOCUMENT_SCHEMAS = [
  'VerificationItem',
  'VerificationStatus',
  'VerificationQueueItem',
  'ReviewDocument',
  'ReviewItem',
  'VerificationReview',
  'Level2Session',
  'ViewUrl',
];
const DOCUMENT_FIELD = /^(nid|selfie|police|documents?$|document[A-Z]|viewUrl)/;

const isCustomerFacing = (path: string) => /^\/v1\/(customer\/|me\b)/.test(path);

/** Every component schema name and property name reachable from `node`. */
function reach(node: unknown, seen: Set<string>, fields: Set<string>): void {
  if (Array.isArray(node)) {
    node.forEach((n) => {
      reach(n, seen, fields);
    });
    return;
  }
  if (typeof node !== 'object' || node === null) {
    return;
  }
  const n = node as Node;
  const ref = typeof n.$ref === 'string' ? n.$ref.split('/').pop() : undefined;
  if (ref !== undefined && !seen.has(ref)) {
    seen.add(ref);
    reach(schemas[ref], seen, fields);
  }
  if (typeof n.properties === 'object' && n.properties !== null) {
    Object.keys(n.properties).forEach((f) => fields.add(f));
  }
  Object.values(n).forEach((v) => {
    reach(v, seen, fields);
  });
}

describe('customer-facing contract', () => {
  const paths = Object.keys(doc.paths).filter(isCustomerFacing);
  const seen = new Set<string>();
  const fields = new Set<string>();
  paths.forEach((p) => {
    reach(doc.paths[p], seen, fields);
  });

  it('covers the customer API', () => {
    expect(paths.length).toBeGreaterThan(20);
    expect(seen.has('Booking')).toBe(true);
  });

  it('never references a verification document schema', () => {
    expect(DOCUMENT_SCHEMAS.filter((s) => seen.has(s))).toEqual([]);
    expect(DOCUMENT_SCHEMAS.every((s) => s in schemas)).toBe(true);
  });

  it('has no field that could carry a document', () => {
    expect([...fields].filter((f) => DOCUMENT_FIELD.test(f))).toEqual([]);
  });

  it('would notice a document field', () => {
    const probe = new Set<string>();
    reach({ $ref: '#/components/schemas/ReviewItem' }, new Set(), probe);
    expect([...probe].some((f) => DOCUMENT_FIELD.test(f))).toBe(true);
  });
});
