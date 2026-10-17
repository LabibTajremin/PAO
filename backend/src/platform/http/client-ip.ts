import { BlockList, isIP } from 'node:net';
import { type NextFunction, type Response } from 'express';
import { type ApiRequest } from './api-request';

const privateNetworks = new BlockList();
privateNetworks.addSubnet('10.0.0.0', 8, 'ipv4');
privateNetworks.addSubnet('172.16.0.0', 12, 'ipv4');
privateNetworks.addSubnet('192.168.0.0', 16, 'ipv4');
privateNetworks.addSubnet('127.0.0.0', 8, 'ipv4');
privateNetworks.addAddress('::1', 'ipv6');
privateNetworks.addSubnet('fc00::', 7, 'ipv6');

/** Writes an IPv4-mapped IPv6 address (`::ffff:10.0.0.5`) as plain IPv4. */
export function normalizeIp(ip: string): string {
  const mapped = /^::ffff:(\d+\.\d+\.\d+\.\d+)$/i.exec(ip);
  return mapped?.[1] ?? ip;
}

/** Reports whether `ip` belongs to a private network (our load balancer). */
export function isPrivateAddress(ip: string): boolean {
  const kind = isIP(ip);
  return kind !== 0 && privateNetworks.check(ip, kind === 4 ? 'ipv4' : 'ipv6');
}

/**
 * Returns the client address. X-Forwarded-For is trusted only when the connection comes
 * from a private address, and then only its rightmost entry, the one our load balancer
 * appended, so clients cannot spoof their address for rate limits.
 */
export function proxiedClientIp(peer: string, forwardedFor: string | string[] | undefined): string {
  const forwarded = [forwardedFor ?? []].flat();
  if (forwarded.length === 0 || !isPrivateAddress(peer)) {
    return peer;
  }
  const last = forwarded[forwarded.length - 1]?.split(',').pop()?.trim() ?? '';
  return isIP(last) === 0 ? peer : normalizeIp(last);
}

/** Middleware storing the client address on the request. */
export function clientIpMiddleware(req: ApiRequest, _res: Response, next: NextFunction): void {
  const peer = normalizeIp(req.socket.remoteAddress ?? '');
  req.clientIp = proxiedClientIp(peer, req.headers['x-forwarded-for']);
  next();
}
