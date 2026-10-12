import { App, isApp } from './notification';
import { render, TEMPLATES } from './templates';

const placeholders = (s: string) => (s.match(/\{\{/g) ?? []).length;

describe('render', () => {
  it('fills a template in English or Bangla', () => {
    const data = { provider: 'Rahim', number: 'PAO-100001' };
    expect(render('booking_accepted', 'en', data)?.body).toBe('Rahim accepted booking PAO-100001.');
    const bn = render('booking_accepted', 'bn', { ...data, provider: 'রহিম' });
    expect(bn?.title).toBe('বুকিং গৃহীত');
    expect(bn?.body).toContain('রহিম');
  });

  it('reads any other language as Bangla and keeps unknown placeholders', () => {
    expect(render('booking_started', 'fr', {})?.body).toBe('বুকিং {{number}}-এর কাজ চলছে।');
  });

  it('refuses an unknown template', () => {
    expect(render('nope', 'en', {})).toBeUndefined();
    expect(render('toString', 'en', {})).toBeUndefined();
  });

  it.each(Object.entries(TEMPLATES))('has both languages for %s', (_name, t) => {
    for (const text of [t.en, t.bn]) {
      expect(text.title).not.toBe('');
      expect(text.body).not.toBe('');
    }
    expect(placeholders(t.en.body)).toBe(placeholders(t.bn.body));
  });
});

describe('isApp', () => {
  it('knows the two apps', () => {
    expect([App.Customer, App.Partner, 'provider'].map(isApp)).toEqual([true, true, false]);
  });
});
