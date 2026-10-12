import { resolve } from 'node:path';

/**
 * The backend package root: `backend/` in a checkout and `/app` in the image. The
 * migrations, seed data and the bundled OpenAPI document are read relative to it.
 */
export const PACKAGE_ROOT = resolve(__dirname, '..', '..');
