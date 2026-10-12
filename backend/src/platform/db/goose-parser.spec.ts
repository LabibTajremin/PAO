import { migrationVersion, parseGooseMigration } from './goose-parser';

describe('migrationVersion', () => {
  it.each([
    ['0001_init.sql', 1],
    ['20240101120000_add.sql', 20240101120000],
    ['init.sql', undefined],
    ['0001_init.txt', undefined],
  ])('reads %s', (name, want) => {
    expect(migrationVersion(name)).toBe(want);
  });
});

describe('parseGooseMigration', () => {
  it('splits statements per direction and keeps blocks whole', () => {
    const sql = [
      '-- leading comment before Up is ignored',
      '-- +goose Up',
      'CREATE SCHEMA a;',
      'CREATE TABLE a.t (',
      '  v int -- trailing comment;',
      '); -- done',
      '-- +goose StatementBegin',
      'CREATE FUNCTION a.f() RETURNS int AS $$',
      'BEGIN RETURN 1; END;',
      '$$ LANGUAGE plpgsql;',
      '-- +goose StatementEnd',
      '',
      '-- +goose Down',
      'DROP SCHEMA a CASCADE;',
      'SELECT 1',
    ].join('\n');
    const m = parseGooseMigration('mod/0002_x.sql', sql);
    expect(m.version).toBe(2);
    expect(m.noTransaction).toBe(false);
    expect(m.up).toHaveLength(3);
    expect(m.up[1]).toContain('v int -- trailing comment;');
    expect(m.up[2]).toContain('BEGIN RETURN 1; END;');
    expect(m.down).toEqual(['DROP SCHEMA a CASCADE;', 'SELECT 1']);
  });

  it('reads NO TRANSACTION', () => {
    const m = parseGooseMigration(
      '0001_x.sql',
      '-- +goose NO TRANSACTION\n-- +goose Up\nSELECT 1;\n',
    );
    expect(m.noTransaction).toBe(true);
    expect(m.down).toEqual([]);
  });

  it.each([
    ['x.sql', '-- +goose Up\nSELECT 1;', 'start with a version'],
    ['0001_x.sql', 'SELECT 1;', 'missing "-- +goose Up"'],
    ['0001_x.sql', '-- +goose Down\nSELECT 1;', 'missing "-- +goose Up"'],
    ['0001_x.sql', '-- +goose Up\n-- +goose ENVSUB ON\n', 'ENVSUB is not supported'],
    ['0001_x.sql', '-- +goose Up\n-- +goose Sideways\n', 'unknown goose annotation'],
  ])('rejects %s %#', (name, sql, message) => {
    expect(() => parseGooseMigration(name, sql)).toThrow(message);
  });
});
