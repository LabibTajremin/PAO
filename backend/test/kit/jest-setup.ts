import { runCleanups } from './cleanup';

// Integration specs talk to real services; building the template database alone can take
// several seconds on a cold start.
jest.setTimeout(60_000);

afterAll(runCleanups);
