import { rmSync } from 'node:fs';
import { tokensFile } from './admins';

/** Forgets this run's admin sessions. */
export default function teardown(): void {
  rmSync(tokensFile, { force: true });
}
