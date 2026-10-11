import { fitsSettingType } from './settings';

describe('fitsSettingType', () => {
  it.each([
    ['integer', '180'],
    ['number', '3.5'],
    ['boolean', 'true'],
    ['boolean', 'F'],
    ['string', 'anything'],
    ['geojson', ''],
    ['geojson', '{"type":"Polygon","coordinates":[[[90,23],[91,23],[91,24],[90,23]]]}'],
  ])('accepts %s %j', (type, value) => {
    expect(fitsSettingType(type, value)).toBe(true);
  });

  it.each([
    ['integer', '-1'],
    ['integer', '1.5'],
    ['integer', '9223372036854775808'],
    ['number', '-0.1'],
    ['number', 'Inf'],
    ['number', '1e999'],
    ['number', 'x'],
    ['boolean', 'yes'],
    ['geojson', '{"type":"Point","coordinates":[90,23]}'],
    ['geojson', '{"type":"Polygon"}'],
    ['geojson', '{"type":"Polygon","coordinates":[]}'],
    ['geojson', 'null'],
    ['geojson', '{'],
    ['unknown', '1'],
  ])('refuses %s %j', (type, value) => {
    expect(fitsSettingType(type, value)).toBe(false);
  });
});
