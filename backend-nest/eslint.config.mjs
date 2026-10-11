// Lint rules mirror docs/build/01-conventions.md: size limits, documented public API,
// type-checked strictness. Generated code (sqlc output, *.gen.ts) is not linted.
import js from '@eslint/js';
import jsdoc from 'eslint-plugin-jsdoc';
import tseslint from 'typescript-eslint';

const sizeRules = {
  'max-lines': ['error', { max: 250, skipBlankLines: false, skipComments: false }],
  'max-lines-per-function': ['error', { max: 40, skipBlankLines: true, skipComments: true }],
  complexity: ['error', 10],
  'max-depth': ['error', 3],
  'max-params': ['error', 4],
};

export default tseslint.config(
  { ignores: ['dist/**', 'coverage/**', 'node_modules/**', '**/sqlc/**', '**/*.gen.ts'] },
  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
    },
    plugins: { jsdoc },
    rules: {
      ...sizeRules,
      'no-console': 'error',
      eqeqeq: ['error', 'always'],
      'id-denylist': ['error', 'utils', 'helper', 'helpers', 'misc', 'stuff', 'temp', 'manager'],
      '@typescript-eslint/no-extraneous-class': ['error', { allowWithDecorator: true }],
      '@typescript-eslint/restrict-template-expressions': ['error', { allowNumber: true }],
      '@typescript-eslint/consistent-type-imports': [
        'error',
        { fixStyle: 'inline-type-imports', disallowTypeAnnotations: false },
      ],
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'jsdoc/require-jsdoc': [
        'error',
        {
          publicOnly: true,
          require: { ClassDeclaration: true, FunctionDeclaration: true },
          contexts: ['TSInterfaceDeclaration', 'TSTypeAliasDeclaration', 'TSEnumDeclaration'],
        },
      ],
    },
  },
  {
    files: ['**/*.spec.ts', '**/*.int-spec.ts', 'test/**/*.ts'],
    rules: {
      'max-lines': ['error', { max: 400, skipBlankLines: false, skipComments: false }],
      'max-lines-per-function': 'off',
      'jsdoc/require-jsdoc': 'off',
      '@typescript-eslint/unbound-method': 'off',
      '@typescript-eslint/no-non-null-assertion': 'off',
    },
  },
  {
    files: ['**/*.mjs', '**/*.cjs', 'jest.config.ts'],
    ...tseslint.configs.disableTypeChecked,
  },
  {
    files: ['**/*.cjs'],
    languageOptions: {
      sourceType: 'commonjs',
      globals: { module: 'writable', require: 'readonly' },
    },
    rules: { '@typescript-eslint/no-require-imports': 'off' },
  },
);
