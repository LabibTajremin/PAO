import { NIL } from 'uuid';
import { type Envelope } from './event-bus';
import { Payload } from './payload';

const env = (payload: unknown) =>
  ({
    id: 'e',
    module: 'm',
    name: 'x.Happened',
    aggregateId: 'a',
    payload,
    occurredAt: new Date(),
  }) as Envelope;

describe('Payload', () => {
  it('reads fields with Go zero values for missing ones', () => {
    const p = new Payload(env({ id: 'abc', n: 2, ok: true, s: 'hi', gone: null }));
    expect([p.id('id'), p.number('n'), p.flag('ok'), p.text('s')]).toEqual(['abc', 2, true, 'hi']);
    expect([p.id('none'), p.number('none'), p.flag('none'), p.text('gone')]).toEqual([
      NIL,
      0,
      false,
      '',
    ]);
  });

  it('fails on wrong types and non-object payloads', () => {
    expect(() => new Payload(env({ n: 'two' })).number('n')).toThrow('n is not a number');
    for (const bad of ['text', null, [1]]) {
      expect(() => new Payload(env(bad))).toThrow('x.Happened: payload is not an object');
    }
  });
});
