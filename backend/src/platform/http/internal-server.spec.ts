import { createServer, type Server } from 'node:http';
import {
  createInternalServer,
  livenessHandler,
  metricsHandler,
  writeJson,
  writeText,
} from './internal-server';
import { closeServer, listen, parseListenAddress } from './listen';

async function get(server: Server, path: string, method = 'GET') {
  const addr = await listen(server, '127.0.0.1:0');
  try {
    const res = await fetch(`http://127.0.0.1:${addr.port}${path}`, { method });
    return { status: res.status, body: await res.text(), type: res.headers.get('content-type') };
  } finally {
    await closeServer(server, 1000);
  }
}

describe('parseListenAddress', () => {
  it.each([
    [':8080', { port: 8080 }],
    ['127.0.0.1:0', { host: '127.0.0.1', port: 0 }],
    ['[::1]:9090', { host: '::1', port: 9090 }],
  ])('parses %s', (addr, want) => {
    expect(parseListenAddress(addr)).toEqual(want);
  });

  it.each(['8080', 'host:', ':99999', ''])('rejects %j', (addr) => {
    expect(() => parseListenAddress(addr)).toThrow('invalid listen address');
  });
});

describe('listen and closeServer', () => {
  it('reports a listener failure', async () => {
    const first = createServer();
    const addr = await listen(first, '127.0.0.1:0');
    await expect(listen(createServer(), `127.0.0.1:${addr.port}`)).rejects.toThrow();
    expect(await closeServer(first, 1000)).toBe(true);
  });

  it('cuts off requests that outlive the drain', async () => {
    const server = createServer(() => {
      // never answers
    });
    const addr = await listen(server, '127.0.0.1:0');
    const pending = fetch(`http://127.0.0.1:${addr.port}/`).catch(() => 'cut');
    await new Promise((r) => setTimeout(r, 50));
    expect(await closeServer(server, 50)).toBe(false);
    expect(await pending).toBe('cut');
  });
});

describe('createInternalServer', () => {
  const metrics = metricsHandler(() =>
    Promise.resolve({ contentType: 'text/plain', body: 'm 1\n' }),
  );

  it('serves metrics and liveness', async () => {
    expect(await get(createInternalServer([metrics, livenessHandler]), '/metrics')).toEqual({
      status: 200,
      body: 'm 1\n',
      type: 'text/plain',
    });
    const live = await get(createInternalServer([metrics, livenessHandler]), '/healthz');
    expect(live).toEqual({ status: 200, body: '{"status":"ok"}\n', type: 'application/json' });
  });

  it('answers 404 for other paths and methods', async () => {
    const server = (): Server => createInternalServer([metrics, livenessHandler]);
    expect((await get(server(), '/other')).status).toBe(404);
    expect((await get(server(), '/metrics', 'POST')).status).toBe(404);
    expect((await get(server(), '/healthz', 'POST')).body).toBe('404 page not found\n');
  });

  it('answers 500 when a handler fails', async () => {
    const failing = createInternalServer([() => Promise.reject(new Error('boom'))]);
    expect(await get(failing, '/')).toMatchObject({ status: 500, body: 'internal error\n' });
  });

  it('writes JSON and text answers', async () => {
    const server = createServer((req, res) => {
      if (req.url === '/json') {
        writeJson(res, 201, { a: 1 });
      } else {
        writeText(res, 400, 'bad');
      }
    });
    expect(await get(server, '/json')).toMatchObject({ status: 201, body: '{"a":1}\n' });
    expect(await get(server, '/text')).toMatchObject({ status: 400, body: 'bad\n' });
  });
});
