// The journeys share one stack and its seeded admins, so files run one at a time.
// Waits on the worker make single journeys slow.
module.exports = {
  testEnvironment: 'node',
  testMatch: ['<rootDir>/**/*.spec.ts'],
  transform: {
    '/node_modules/(@scure|@noble)/.+\\.js$': [
      '@swc/jest',
      { jsc: { target: 'es2023' }, module: { type: 'commonjs' } },
    ],
    '^.+\\.ts$': ['@swc/jest', { jsc: { parser: { syntax: 'typescript' }, target: 'es2023' } }],
  },
  // otplib's crypto and base32 plugins ship ES modules only; Jest needs them as CommonJS.
  transformIgnorePatterns: ['/node_modules/(?!(@scure|@noble)/)'],
  moduleFileExtensions: ['ts', 'js', 'json'],
  globalTeardown: '<rootDir>/support/teardown.ts',
  setupFilesAfterEnv: ['<rootDir>/support/cleanup-hook.ts'],
  testTimeout: 300_000,
  slowTestThreshold: 60,
};
