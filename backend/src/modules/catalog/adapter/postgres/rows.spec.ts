import { groupBy, toNumber } from './rows';

describe('catalog rows', () => {
  it('reads bigint strings as safe integers only', () => {
    expect(toNumber('50000')).toBe(50_000);
    expect(() => toNumber('9007199254740993')).toThrow('not a safe integer');
  });

  it('groups items in order', () => {
    const groups = groupBy(['a1', 'b1', 'a2'], (s) => s.charAt(0));
    expect([...groups]).toEqual([
      ['a', ['a1', 'a2']],
      ['b', ['b1']],
    ]);
  });
});
