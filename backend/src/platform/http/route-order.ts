import { type INestApplication } from '@nestjs/common';

/** The part of an Express router layer the reordering reads. */
interface Layer {
  readonly route?: { readonly path: unknown };
  match(path: string): boolean;
}

function literal(layer: Layer): string | undefined {
  const path = layer.route?.path;
  return typeof path === 'string' && !/[:*{]/.test(path) ? path : undefined;
}

/**
 * Moves each literal route in front of the first earlier route that would shadow it.
 * Nest registers routes module by module, so `/v1/customer/providers/{providerId}`
 * (provider) would otherwise catch `/v1/customer/providers/nearby` (booking); the Go
 * router, like the spec, prefers the literal path.
 */
export function preferLiteralRoutes(stack: Layer[]): void {
  for (const layer of [...stack]) {
    const path = literal(layer);
    if (path === undefined) {
      continue;
    }
    const at = stack.indexOf(layer);
    const shadow = stack.find((l, j) => j < at && l.route !== undefined && l.match(path));
    if (shadow !== undefined && literal(shadow) === undefined) {
      stack.splice(at, 1);
      stack.splice(stack.indexOf(shadow), 0, layer);
    }
  }
}

/**
 * Initialises the app, which registers every route, then applies
 * {@link preferLiteralRoutes}. It is a plain call rather than a wrapped `app.init`
 * because the app NestFactory returns is a proxy that ignores property writes.
 */
export async function initWithOrderedRoutes(app: INestApplication): Promise<void> {
  await app.init();
  const express = app.getHttpAdapter().getInstance() as { router: { stack: Layer[] } };
  preferLiteralRoutes(express.router.stack);
}
