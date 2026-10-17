import { version } from 'uuid';
import { ID_GENERATOR, SequenceIdGenerator, UuidV7Generator } from './id-generator';

describe('UuidV7Generator', () => {
  it('issues time-ordered version 7 ids', () => {
    const ids = new UuidV7Generator();
    const a = ids.newId();
    const b = ids.newId();
    expect(version(a)).toBe(7);
    expect(a < b).toBe(true);
    expect(typeof ID_GENERATOR).toBe('symbol');
  });
});

describe('SequenceIdGenerator', () => {
  it('replays the given ids, then generates', () => {
    const fixed = '00000000-0000-7000-8000-000000000001';
    const ids = new SequenceIdGenerator([fixed]);
    expect(ids.newId()).toBe(fixed);
    expect(version(ids.newId())).toBe(7);
  });
});
