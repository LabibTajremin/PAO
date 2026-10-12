import { Writable } from 'node:stream';
import { Test } from '@nestjs/testing';
import { type AppConfig } from '../config/app-config';
import { ConfigModule } from '../config/config.module';
import { createLogger, discardLogger, LOGGER, type Logger, NestLoggerAdapter } from './logger';
import { LoggingModule } from './logging.module';
import { currentRequestContext, runWithRequestContext, setRequestUserId } from './request-context';

function capture(): { lines: () => Record<string, unknown>[]; stream: Writable } {
  const chunks: string[] = [];
  const stream = new Writable({
    write(chunk: Buffer, _enc, done) {
      chunks.push(chunk.toString());
      done();
    },
  });
  return {
    stream,
    lines: () =>
      chunks
        .join('')
        .trim()
        .split('\n')
        .map((l) => JSON.parse(l) as Record<string, unknown>),
  };
}

describe('createLogger', () => {
  it('adds the request context to every record', () => {
    const out = capture();
    const log = createLogger('info', out.stream).child({ module: 'booking' });
    runWithRequestContext({ requestId: 'req-1' }, () => {
      setRequestUserId('user-1');
      log.info({ booking_id: 'b1' }, 'accepted');
    });
    const [rec] = out.lines();
    expect(rec).toMatchObject({
      level: 'INFO',
      msg: 'accepted',
      module: 'booking',
      request_id: 'req-1',
      user_id: 'user-1',
      booking_id: 'b1',
    });
    expect(typeof rec?.time).toBe('string');
  });

  it('writes no context fields outside a request', () => {
    const out = capture();
    const log = createLogger('debug', out.stream);
    setRequestUserId('ignored');
    log.debug('plain');
    expect(out.lines()[0]).not.toHaveProperty('request_id');
    expect(currentRequestContext()).toBeUndefined();
    discardLogger().info('dropped');
    expect(createLogger('error').level).toBe('error');
  });
});

describe('NestLoggerAdapter', () => {
  it('maps every Nest level', () => {
    const out = capture();
    const adapter = new NestLoggerAdapter(createLogger('debug', out.stream));
    adapter.log('l', 'Ctx');
    adapter.error('e', 'trace', 'Ctx');
    adapter.warn('w', 'Ctx');
    adapter.debug('d', 'Ctx');
    adapter.verbose('v', 'Ctx');
    expect(out.lines().map((r) => r.level)).toEqual(['INFO', 'ERROR', 'WARN', 'DEBUG']);
  });
});

describe('LoggingModule', () => {
  it('provides a logger at the configured level', async () => {
    const ref = await Test.createTestingModule({
      imports: [ConfigModule.forRoot({ logLevel: 'warn' } as AppConfig), LoggingModule],
    }).compile();
    expect(ref.get<Logger>(LOGGER).level).toBe('warn');
  });
});
