import { generateKeyPairSync } from 'node:crypto';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { createServer, type Server } from 'node:http';
import { type AddressInfo } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { type AppConfig } from '../../../../platform/config/app-config';
import { discardLogger } from '../../../../platform/logging/logger';
import { InvalidTokenError } from '../../port/ports';
import { CapturePusher } from './capture';
import { FcmPusher, fcmFromCredentials } from './fcm';
import { pushProviders, pusherFor } from './pushers';

/** A throwaway service-account key; parsing it needs no network. */
function serviceAccount(): string {
  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  return JSON.stringify({
    type: 'service_account',
    project_id: 'pao-test',
    client_email: 'push@pao-test.iam.gserviceaccount.com',
    private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
    token_uri: 'https://oauth2.googleapis.com/token',
  });
}

const push = {
  title: 'Booking accepted',
  body: 'Rahim accepted',
  data: { type: 'booking_accepted' },
};

describe('FcmPusher', () => {
  let server: Server;
  let status = 200;
  let received: { auth?: string; body: unknown } = { body: undefined };
  let url = '';

  beforeAll(async () => {
    server = createServer((req, res) => {
      let raw = '';
      req.on('data', (c: Buffer) => (raw += c.toString()));
      req.on('end', () => {
        received = { auth: req.headers.authorization, body: JSON.parse(raw) };
        res.writeHead(status).end('nope');
      });
    });
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
    url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  });

  it('builds the endpoint from the service account', () => {
    expect(fcmFromCredentials(serviceAccount()).endpoint).toBe(
      'https://fcm.googleapis.com/v1/projects/pao-test/messages:send',
    );
    expect(() => fcmFromCredentials('{}')).toThrow('fcm credentials');
    expect(() => fcmFromCredentials('{')).toThrow();
  });

  it('sends the message and tells dead tokens from failures', async () => {
    const fcm = new FcmPusher(url, () => Promise.resolve('access'));
    await fcm.push('tok', push);
    expect(received).toEqual({
      auth: 'Bearer access',
      body: {
        message: {
          token: 'tok',
          notification: { title: 'Booking accepted', body: 'Rahim accepted' },
          data: { type: 'booking_accepted' },
          android: { priority: 'high' },
        },
      },
    });
    for (const s of [404, 400]) {
      status = s;
      await expect(fcm.push('tok', push)).rejects.toBeInstanceOf(InvalidTokenError);
    }
    status = 500;
    await expect(fcm.push('tok', push)).rejects.toThrow('fcm: 500 nope');
    await new Promise((resolve) => server.close(resolve));
    await expect(fcm.push('tok', push)).rejects.toThrow();
  });

  it('fails when Google gives no access token', async () => {
    const fcm = fcmFromCredentials(serviceAccount());
    const jwt = (await import('google-auth-library')).JWT.prototype;
    type GetToken = () => Promise<{ token: string | null }>;
    const spy = jest.spyOn(jwt as unknown as { getAccessToken: GetToken }, 'getAccessToken');
    spy.mockResolvedValue({ token: null });
    await expect(fcm.push('tok', push)).rejects.toThrow('no access token');
    spy.mockResolvedValue({ token: 'ok' });
    jest.spyOn(globalThis, 'fetch').mockResolvedValue(new Response(null, { status: 200 }));
    await fcm.push('tok', push);
    jest.restoreAllMocks();
  });
});

describe('CapturePusher', () => {
  it('rejects dead and broken tokens and keeps the latest pushes', async () => {
    const c = new CapturePusher(discardLogger());
    await expect(c.push('invalid-1', push)).rejects.toBeInstanceOf(InvalidTokenError);
    await expect(c.push('broken-1', push)).rejects.toThrow('push service unavailable');
    for (let i = 0; i < 1001; i++) {
      await c.push(`tok-${i % 2}`, { ...push, title: String(i) });
    }
    const got = c.sentTo('tok-0');
    expect(got).toHaveLength(500);
    expect(got.at(-1)?.title).toBe('1000');
  });
});

describe('pusherFor', () => {
  const config = (c: Partial<AppConfig>) => c as AppConfig;

  it('uses FCM only when asked and exposes the capture otherwise', async () => {
    const capture = await pusherFor(config({ pushAdapter: 'log' }), discardLogger());
    expect(capture).toBeInstanceOf(CapturePusher);
    const file = join(mkdtempSync(join(tmpdir(), 'fcm-')), 'key.json');
    writeFileSync(file, serviceAccount());
    const fcm = await pusherFor(
      config({ pushAdapter: 'fcm', fcmCredentialsFile: file }),
      discardLogger(),
    );
    expect(fcm).toBeInstanceOf(FcmPusher);
    const seam = pushProviders[1] as { useFactory: (p: unknown) => unknown };
    expect(seam.useFactory(capture)).toBe(capture);
    expect(seam.useFactory(fcm)).toBeUndefined();
  });
});
