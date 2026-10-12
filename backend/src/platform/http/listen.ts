import { type Server } from 'node:http';
import { type AddressInfo } from 'node:net';

/** A TCP listen address split from Go's `host:port` form (`:8080` means every interface). */
export interface ListenAddress {
  readonly host?: string;
  readonly port: number;
}

/** Parses `:8080`, `127.0.0.1:0` or `[::1]:9090`; throws on anything else. */
export function parseListenAddress(addr: string): ListenAddress {
  const match = /^(?:\[([^\]]+)\]|([^:]*)):(\d{1,5})$/.exec(addr);
  const port = Number(match?.[3]);
  if (!match || port > 65535) {
    throw new Error(`invalid listen address ${JSON.stringify(addr)}`);
  }
  const host = match[1] ?? match[2];
  return host ? { host, port } : { port };
}

/** Starts `server` on `addr` and resolves with the bound address. */
export function listen(server: Server, addr: string): Promise<AddressInfo> {
  const { host, port } = parseListenAddress(addr);
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, host, () => {
      server.off('error', reject);
      resolve(server.address() as AddressInfo);
    });
  });
}

/**
 * Stops accepting connections and waits for in-flight requests, cutting them off after
 * `drainMs` so shutdown is bounded. Resolves false when the drain timed out.
 */
export function closeServer(server: Server, drainMs: number): Promise<boolean> {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      server.closeAllConnections();
      resolve(false);
    }, drainMs);
    server.close(() => {
      clearTimeout(timer);
      resolve(true);
    });
    server.closeIdleConnections();
  });
}
