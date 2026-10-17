import { type DomainEvent } from '../events/domain-event';
import { type Envelope, EventBus } from '../events/event-bus';
import { nextDailyRun } from './scheduler';
import { Ticker } from './ticker';

describe('nextDailyRun', () => {
  it('fires at the Dhaka wall-clock time', () => {
    // 19:30 UTC is 01:30 in Dhaka: the 02:00 run is 30 minutes later, the same Dhaka day.
    expect(nextDailyRun(new Date('2026-10-09T19:30:00Z'), 2, 0)).toEqual(
      new Date('2026-10-09T20:00:00Z'),
    );
    // Exactly at 02:00 Dhaka the next run is tomorrow.
    expect(nextDailyRun(new Date('2026-10-09T20:00:00Z'), 2, 0)).toEqual(
      new Date('2026-10-10T20:00:00Z'),
    );
  });
});

describe('Ticker', () => {
  it('runs until stopped and never after', async () => {
    let runs = 0;
    const ticker = new Ticker(
      () => 1,
      () => {
        runs++;
        return Promise.resolve();
      },
    );
    ticker.start();
    await new Promise((r) => setTimeout(r, 30));
    await ticker.stop();
    const seen = runs;
    await new Promise((r) => setTimeout(r, 20));
    expect(seen).toBeGreaterThan(1);
    expect(runs).toBe(seen);
  });
});

interface Pinged extends DomainEvent<'test.Pinged'> {
  readonly n: number;
}

describe('EventBus', () => {
  it('delivers to every subscriber and joins their failures', async () => {
    const bus = new EventBus();
    const got: number[] = [];
    bus.subscribe<Pinged>('test.Pinged', 'a', (env) => {
      got.push(env.payload.n);
      return Promise.resolve();
    });
    bus.subscribe('test.Pinged', 'b', () => Promise.reject(new Error('down')));
    bus.subscribe('test.Pinged', 'c', () => Promise.reject(new Error('also')));
    const env: Envelope<Pinged> = {
      id: 'e1',
      module: 'test',
      name: 'test.Pinged',
      aggregateId: 'x',
      payload: { name: 'test.Pinged', n: 7 },
      occurredAt: new Date(),
    };
    await expect(bus.dispatch(env)).rejects.toThrow('b: down\nc: also');
    expect(got).toEqual([7]);
    await expect(bus.dispatch({ ...env, name: 'test.Nobody' })).resolves.toBeUndefined();
    const odd = new EventBus();
    // A handler from a library may reject with a plain string; the bus still names it.
    // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors -- the case under test
    odd.subscribe('test.Pinged', 'odd', () => Promise.reject('x'));
    await expect(odd.dispatch(env)).rejects.toThrow('odd: x');
  });
});
