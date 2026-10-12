import { readFileSync } from 'node:fs';
import { join } from 'node:path';

/** Parses KEY=value lines, as stack.sh writes them; a missing file reads as empty. */
export function readEnv(path: string): Map<string, string> {
  const env = new Map<string, string>();
  let text: string;
  try {
    text = readFileSync(path, 'utf8');
  } catch {
    return env;
  }
  for (const row of text.split('\n')) {
    const at = row.indexOf('=');
    if (at > 0) env.set(row.slice(0, at), row.slice(at + 1));
  }
  return env;
}

/** Where the e2e stack listens and the seeded admins' password. */
export interface Stack {
  readonly api: string;
  readonly worker: string;
  readonly adminPassword: string;
}

/** The directory stack.sh writes .stack.env and .admins.env into. */
export const e2eDir = join(__dirname, '..', '..');

function loadStack(): Stack {
  const file = readEnv(join(e2eDir, '.stack.env'));
  const value = (key: string): string => {
    const found = process.env[key] ?? file.get(key);
    if (found === undefined || found === '') {
      throw new Error(`${key} is not set: start the stack with test/e2e/stack.sh`);
    }
    return found;
  };
  return {
    api: value('PAO_E2E_API'),
    worker: value('PAO_E2E_WORKER'),
    adminPassword: value('PAO_E2E_ADMIN_PASSWORD'),
  };
}

let loaded: Stack | undefined;

/** The running stack, from the environment or else test/e2e/.stack.env. */
export function stack(): Stack {
  loaded ??= loadStack();
  return loaded;
}
