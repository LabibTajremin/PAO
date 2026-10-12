import { covers } from './area';
import { addressProblem, inBangladesh, profileProblem } from './customer';

const banani = { lat: 23.7937, lng: 90.4066 };
const ok = { label: 'home', line1: 'House 12, Road 5', line2: '', area: '', location: banani };

describe('customer profile', () => {
  it.each([
    ['N', 'bn'],
    ['ন'.repeat(81), 'bn'],
    ['Nusrat', 'fr'],
  ])('refuses %s / %s', (name, language) => {
    expect(profileProblem(name, language)).toBe('invalid');
  });

  it('accepts a Bangla name', () => {
    expect(profileProblem('নুসরাত', 'bn')).toBeNull();
  });
});

describe('address', () => {
  it('accepts a pin in Banani', () => {
    expect(addressProblem(ok)).toBeNull();
    expect(inBangladesh(banani)).toBe(true);
  });

  it.each([
    { label: 'farm' },
    { line1: 'ab' },
    { line2: 'x'.repeat(201) },
    { area: 'x'.repeat(81) },
  ])('refuses %j', (change) => {
    expect(addressProblem({ ...ok, ...change })).toBe('invalid');
  });

  it('refuses swapped coordinates as outside the country', () => {
    const swapped = { ...ok, location: { lat: banani.lng, lng: banani.lat } };
    expect(addressProblem(swapped)).toBe('outside_country');
  });
});

const square =
  '{"type":"Polygon","coordinates":[[[90,23],[91,23],[91,24],[90,24],[90,23]],[[90.5,23.5],[90.6,23.5],[90.6,23.6],[90.5,23.6],[90.5,23.5]]]}';
const multi =
  '{"type":"MultiPolygon","coordinates":[[[[88,22],[89,22],[89,23],[88,22]]],[[[90,23],[91,23],[91,24],[90,24],[90,23]]]]}';

describe('launch area', () => {
  it.each([
    ['', banani, true],
    [square, banani, true],
    [square, { lat: 23.55, lng: 90.55 }, false],
    [square, { lat: 22, lng: 90.5 }, false],
    [multi, banani, true],
    ['{"type":"Polygon","coordinates":[]}', banani, false],
    ['{"type":"Point","coordinates":[90,23]}', banani, false],
    ['{"type":"Polygon"}', banani, false],
    ['{"type":"Polygon","coordinates":[[[90,23],[91]]]}', banani, false],
    ['{', banani, false],
  ])('case %#', (area, p, want) => {
    expect(covers(area, p)).toBe(want);
  });
});
