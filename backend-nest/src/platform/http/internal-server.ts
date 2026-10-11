import { createServer, type IncomingMessage, type Server, type ServerResponse } from 'node:http';

/**
 * Handles a request on an internal (non-API) server and reports whether it did, so
 * handlers can be chained: metrics, liveness, test hooks.
 */
export type InternalHandler = (req: IncomingMessage, res: ServerResponse) => Promise<boolean>;

/** Writes `body` as JSON with a trailing newline, as Go's json.Encoder does. */
export function writeJson(res: ServerResponse, status: number, body: unknown): void {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body) + '\n');
}

/** Writes a plain-text answer, as Go's http.Error does. */
export function writeText(res: ServerResponse, status: number, text: string): void {
  res.writeHead(status, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end(text + '\n');
}

/** Returns the request path and query of `req`. */
export function requestUrl(req: IncomingMessage): URL {
  return new URL(req.url ?? '/', 'http://internal');
}

/** Serves the metrics registry on GET /metrics. */
export function metricsHandler(
  render: () => Promise<{ contentType: string; body: string }>,
): InternalHandler {
  return async (req, res) => {
    if (req.method !== 'GET' || requestUrl(req).pathname !== '/metrics') {
      return false;
    }
    const out = await render();
    res.writeHead(200, { 'Content-Type': out.contentType });
    res.end(out.body);
    return true;
  };
}

/** Answers GET /healthz with 200 while the process can serve HTTP at all. */
export const livenessHandler: InternalHandler = (req, res) => {
  if (req.method !== 'GET' || requestUrl(req).pathname !== '/healthz') {
    return Promise.resolve(false);
  }
  writeJson(res, 200, { status: 'ok' });
  return Promise.resolve(true);
};

/** Builds a small HTTP server that tries `handlers` in order and answers 404 otherwise. */
export function createInternalServer(handlers: readonly InternalHandler[]): Server {
  return createServer((req, res) => {
    void (async () => {
      try {
        for (const handle of handlers) {
          if (await handle(req, res)) {
            return;
          }
        }
        writeText(res, 404, '404 page not found');
      } catch {
        writeText(res, 500, 'internal error');
      }
    })();
  });
}
