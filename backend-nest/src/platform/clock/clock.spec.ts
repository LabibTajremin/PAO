import { CLOCK, DHAKA_OFFSET_MS, SystemClock } from './clock';
import { FakeClock } from './fake-clock';

describe('SystemClock', () => {
  it('reports the current time', () => {
    const before = Date.now();
    expect(new SystemClock().now().getTime()).toBeGreaterThanOrEqual(before);
    expect(typeof CLOCK).toBe('symbol');
  });
});

describe('FakeClock', () => {
  it('advances and is set by hand, never sharing its Date', () => {
    const start = new Date('2026-10-09T10:00:00Z');
    const clock = new FakeClock(start);
    clock.advance(60_000);
    expect(clock.now().toISOString()).toBe('2026-10-09T10:01:00.000Z');
    clock.now().setTime(0);
    clock.set(start);
    expect(clock.now()).toEqual(start);
  });
});

describe('DHAKA_OFFSET_MS', () => {
  it('is UTC+6', () => {
    expect(DHAKA_OFFSET_MS).toBe(6 * 3600 * 1000);
  });
});
