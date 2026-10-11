import { createServer, type Server } from 'node:http';
import { type AddressInfo } from 'node:net';
import { UuidV7Generator } from '../../../../platform/ids/id-generator';
import { discardLogger } from '../../../../platform/logging/logger';
import { CapturedSms, ConsoleSms, SslWirelessSms } from './sms-senders';

describe('console and capture adapters', () => {
  it('log, and keep the newest message per phone', async () => {
    await expect(new ConsoleSms(discardLogger()).send('+8801712345678', 'hi')).resolves.toBe(
      undefined,
    );
    const c = new CapturedSms();
    await c.send('+8801712345678', 'code 123456');
    expect(c.last('+8801712345678')).toBe('code 123456');
    expect(c.normalizePhone('01712345678')).toBe('+8801712345678');
  });
});

describe('SSL Wireless adapter', () => {
  let server: Server;
  let url: string;
  let got: Record<string, string> = {};
  let answer = '{"status_code":200}';

  beforeAll(async () => {
    server = createServer((req, res) => {
      let body = '';
      req.on('data', (chunk: Buffer) => (body += chunk.toString()));
      req.on('end', () => {
        got = JSON.parse(body) as Record<string, string>;
        res.end(answer);
      });
    });
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
    url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  });

  afterAll(() => new Promise((resolve) => server.close(resolve)));

  const sender = (endpoint: string) =>
    new SslWirelessSms(
      { endpoint, apiToken: 'tok', sid: 'PAO', timeoutMs: 2000 },
      new UuidV7Generator(),
    );

  it('posts the message and reports rejections and unreachable gateways', async () => {
    await sender(url).send('+8801712345678', 'hi');
    expect(got).toMatchObject({ msisdn: '8801712345678', api_token: 'tok', sid: 'PAO', sms: 'hi' });
    expect(got.csms_id).toHaveLength(20);
    answer = '{"status_code":4001}';
    await expect(sender(url).send('+8801712345678', 'hi')).rejects.toThrow('status 4001');
    answer = 'not json';
    await expect(sender(url).send('+8801712345678', 'hi')).rejects.toThrow('status 0');
    await expect(sender('http://127.0.0.1:1').send('+8801712345678', 'hi')).rejects.toThrow(
      'sms gateway',
    );
  });
});
