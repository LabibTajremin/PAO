import { type INestApplication, RequestMethod, type Type } from '@nestjs/common';
import { METHOD_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { ModulesContainer } from '@nestjs/core';
import { declaredPermission, FROM_SPEC } from './permissions';
import { type NonSpecRoute } from './spec-match.middleware';
import { type OpenApiDocument, SpecRoutes } from './spec-routes';

/** How the controllers of an app compare with the contract. */
export interface RouteSpecReport {
  /** Routes whose permission decorator differs from the operation's x-permission. */
  readonly mismatched: string[];
  /** Routes that are neither in the contract nor declared as non-spec routes. */
  readonly undocumented: string[];
  /** Spec operations no controller serves (`METHOD /path {operationId}`). */
  readonly unserved: string[];
}

interface ControllerRoute {
  readonly method: string;
  readonly path: string;
  readonly permission: string | symbol | undefined;
}

function joinPath(...parts: unknown[]): string {
  const joined = parts
    .flatMap((p) => (Array.isArray(p) ? (p as unknown[]) : [p]))
    .filter((p): p is string => typeof p === 'string' && p !== '' && p !== '/')
    .join('/');
  return ('/' + joined).replace(/\/+/g, '/').replace(/:([A-Za-z0-9_]+)/g, '{$1}');
}

function controllerRoutes(app: INestApplication): ControllerRoute[] {
  const controllers = [...app.get(ModulesContainer).values()].flatMap((m) =>
    [...m.controllers.values()].map((w) => w.metatype as Type),
  );
  return controllers.flatMap((controller) => {
    const prefix: unknown = Reflect.getMetadata(PATH_METADATA, controller);
    const proto = controller.prototype as Record<string, unknown>;
    return Object.getOwnPropertyNames(proto)
      .map((name) => proto[name])
      .filter((handler): handler is object =>
        Reflect.hasMetadata(METHOD_METADATA, handler as object),
      )
      .map((handler) => ({
        method: RequestMethod[Reflect.getMetadata(METHOD_METADATA, handler) as number] ?? '',
        path: joinPath(prefix, Reflect.getMetadata(PATH_METADATA, handler)),
        permission: declaredPermission(handler, controller),
      }));
  });
}

/**
 * Compares the app's routes with the contract: every route must be a spec operation
 * whose permission decorator equals its `x-permission`, and every operation should be
 * served. Module specs assert on their own operations; the composition check asserts
 * that nothing is left over.
 */
export function checkRoutesAgainstSpec(
  app: INestApplication,
  doc: OpenApiDocument,
  nonSpec: readonly NonSpecRoute[] = [],
): RouteSpecReport {
  const spec = new SpecRoutes(doc);
  const report: RouteSpecReport = { mismatched: [], undocumented: [], unserved: [] };
  const served = new Set<string>();
  for (const route of controllerRoutes(app).filter((r) => r.permission !== FROM_SPEC)) {
    const name = `${route.method} ${route.path}`;
    const match = spec.match(route.method, route.path);
    if (typeof match === 'string') {
      if (!nonSpec.some((r) => r.method === route.method && r.path === route.path)) {
        report.undocumented.push(name);
      }
      continue;
    }
    served.add(match.id);
    if (route.permission !== match.permission) {
      report.mismatched.push(
        `${name}: decorator ${String(route.permission)}, spec ${String(match.permission)}`,
      );
    }
  }
  for (const op of spec.operations().filter((o) => !served.has(o.id))) {
    report.unserved.push(`${op.method.toUpperCase()} ${op.pathTemplate} ${op.id}`);
  }
  return report;
}
