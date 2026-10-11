// Two projects share one coverage report: unit specs run anywhere, integration specs
// need the Postgres and Redis endpoints from the environment (ADR-0008). The gate is
// 100% of hand-written code; generated code and composition roots are excluded.
import type { Config } from 'jest';

const transform: Config['transform'] = {
  '^.+\\.ts$': [
    '@swc/jest',
    {
      jsc: {
        parser: { syntax: 'typescript', decorators: true },
        transform: { legacyDecorator: true, decoratorMetadata: true },
        target: 'es2023',
      },
    },
  ],
};

const shared: Config = {
  rootDir: '.',
  testEnvironment: 'node',
  transform,
  moduleFileExtensions: ['ts', 'js', 'json'],
};

const config: Config = {
  projects: [
    { ...shared, displayName: 'unit', testMatch: ['<rootDir>/src/**/*.spec.ts'] },
    {
      ...shared,
      displayName: 'integration',
      testMatch: ['<rootDir>/src/**/*.int-spec.ts', '<rootDir>/test/**/*.int-spec.ts'],
      slowTestThreshold: 30,
    },
  ],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.spec.ts',
    '!src/**/*.int-spec.ts',
    '!src/**/*.gen.ts',
    '!src/**/sqlc/**',
    '!src/main.ts',
    '!src/worker.ts',
    '!src/migrate.ts',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text-summary', 'lcov', 'json-summary'],
  coverageThreshold: { global: { statements: 100, lines: 100, functions: 100 } },
};

export default config;
