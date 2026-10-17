import { availableParallelism } from 'node:os';
import { isUniqueViolation } from './database';
import { parseGoDuration, poolConfig } from './pool-config';

describe('parseGoDuration', () => {
  it.each([
    ['1h', 3_600_000],
    ['1h30m', 5_400_000],
    ['90s', 90_000],
    ['250ms', 250],
    ['1.5s', 1500],
    ['', undefined],
    ['10', undefined],
    ['1d', undefined],
  ])('parses %j', (text, want) => {
    expect(parseGoDuration(text)).toBe(want);
  });
});

describe('poolConfig', () => {
  it('uses pgxpool defaults', () => {
    const c = poolConfig('postgres://pao:pao@db:5432/pao?sslmode=disable');
    expect(c).toEqual({
      connectionString: 'postgres://pao:pao@db:5432/pao?sslmode=disable',
      max: Math.max(4, availableParallelism()),
      maxLifetimeSeconds: 3600,
      idleTimeoutMillis: 1_800_000,
      connectionTimeoutMillis: 0,
    });
  });

  it('reads and strips pool settings from the URL', () => {
    const c = poolConfig(
      'postgres://db/pao?pool_max_conns=7&pool_max_conn_lifetime=90s&pool_max_conn_idle_time=1m&pool_min_conns=1&connect_timeout=2',
    );
    expect(c).toMatchObject({
      connectionString: 'postgres://db/pao',
      max: 7,
      maxLifetimeSeconds: 90,
      idleTimeoutMillis: 60_000,
      connectionTimeoutMillis: 2000,
    });
  });

  it('ignores malformed values and rejects malformed URLs', () => {
    const c = poolConfig('postgres://db/pao?pool_max_conns=x&pool_max_conn_lifetime=forever');
    expect(c.max).toBe(Math.max(4, availableParallelism()));
    expect(c.maxLifetimeSeconds).toBe(3600);
    expect(() => poolConfig('postgres://%zz')).toThrow();
  });
});

describe('isUniqueViolation', () => {
  const dup = Object.assign(new Error('dup'), { code: '23505', constraint: 'uq' });
  it.each([
    [dup, undefined, true],
    [dup, '', true],
    [dup, 'uq', true],
    [new Error('wrapped', { cause: dup }), 'uq', true],
    [dup, 'other', false],
    [Object.assign(new Error('fk'), { code: '23503' }), undefined, false],
    [new Error('plain'), undefined, false],
    ['not an error', undefined, false],
  ])('case %#', (err, constraint, want) => {
    expect(isUniqueViolation(err, constraint)).toBe(want);
  });
});
