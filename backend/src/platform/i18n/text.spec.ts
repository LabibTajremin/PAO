import { type Language, type Text } from './text';

describe('Text', () => {
  it('holds a value in both product languages', () => {
    const name: Text = { en: 'Electrician', bn: 'ইলেকট্রিশিয়ান' };
    const pick = (lang: Language): string => name[lang];
    expect(pick('en')).toBe('Electrician');
    expect(pick('bn')).toBe('ইলেকট্রিশিয়ান');
  });
});
