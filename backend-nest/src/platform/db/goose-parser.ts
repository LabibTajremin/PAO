/** One goose-format migration file, split into the statements of each direction. */
export interface GooseMigration {
  readonly version: number;
  readonly source: string;
  readonly up: readonly string[];
  readonly down: readonly string[];
  /** `-- +goose NO TRANSACTION`: statements run outside a transaction. */
  readonly noTransaction: boolean;
}

interface ParseState {
  direction?: 'up' | 'down';
  inBlock: boolean;
  buffer: string[];
  up: string[];
  down: string[];
  noTransaction: boolean;
  sawUp: boolean;
}

const ANNOTATION = /^--\s*\+goose\s+(.+?)\s*$/i;

/** Returns the version goose reads from a file name (`0001_init.sql` is 1), or undefined. */
export function migrationVersion(fileName: string): number | undefined {
  const match = /^(\d+)_.*\.sql$/.exec(fileName);
  return match ? Number(match[1]) : undefined;
}

// Goose ends a statement at a line whose last non-comment text ends with a semicolon.
function endsStatement(line: string): boolean {
  return line.replace(/--.*$/, '').trimEnd().endsWith(';');
}

function flush(state: ParseState): void {
  const statement = state.buffer.join('\n').trim();
  state.buffer = [];
  if (statement !== '' && state.direction) {
    state[state.direction].push(statement);
  }
}

function annotate(state: ParseState, command: string, source: string): void {
  switch (command.toLowerCase()) {
    case 'up':
    case 'down':
      flush(state);
      state.direction = command.toLowerCase() as 'up' | 'down';
      state.sawUp ||= state.direction === 'up';
      return;
    case 'statementbegin':
      state.inBlock = true;
      return;
    case 'statementend':
      state.inBlock = false;
      flush(state);
      return;
    case 'no transaction':
      state.noTransaction = true;
      return;
    case 'envsub on':
    case 'envsub off':
      throw new Error(`${source}: goose ENVSUB is not supported`);
    default:
      throw new Error(`${source}: unknown goose annotation "${command}"`);
  }
}

function addLine(state: ParseState, line: string): void {
  if (!state.direction) {
    return;
  }
  state.buffer.push(line);
  if (!state.inBlock && endsStatement(line)) {
    flush(state);
  }
}

/** Parses a goose SQL migration (`-- +goose Up/Down`, `StatementBegin/End`). */
export function parseGooseMigration(source: string, sql: string): GooseMigration {
  const version = migrationVersion(source.split('/').pop() ?? '');
  if (version === undefined) {
    throw new Error(`${source}: migration file names start with a version, e.g. 0001_init.sql`);
  }
  const state: ParseState = {
    inBlock: false,
    buffer: [],
    up: [],
    down: [],
    noTransaction: false,
    sawUp: false,
  };
  for (const line of sql.split(/\r?\n/)) {
    const annotation = ANNOTATION.exec(line.trim());
    if (annotation) {
      annotate(state, annotation[1] ?? '', source);
    } else {
      addLine(state, line);
    }
  }
  flush(state);
  if (!state.sawUp) {
    throw new Error(`${source}: missing "-- +goose Up" annotation`);
  }
  return { version, source, up: state.up, down: state.down, noTransaction: state.noTransaction };
}
