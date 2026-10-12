// Same rules as backend-nest/eslint.config.mjs, minus the NestJS-only ones.
import js from '@eslint/js';
import jsdoc from 'eslint-plugin-jsdoc';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['node_modules/**'] },
  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
    },
    plugins: { jsdoc },
    rules: {
      'max-lines': ['error', { max: 250, skipBlankLines: false, skipComments: false }],
      'max-lines-per-function': ['error', { max: 40, skipBlankLines: true, skipComments: true }],
      complexity: ['error', 10],
      'max-depth': ['error', 3],
      'max-params': ['error', 4],
      'no-console': 'error',
      eqeqeq: ['error', 'always'],
      'id-denylist': ['error', 'utils', 'helper', 'helpers', 'misc', 'stuff', 'temp', 'manager'],
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
    files: ['**/*.spec.ts'],
    rules: {
      'max-lines': ['error', { max: 400, skipBlankLines: false, skipComments: false }],
      'max-lines-per-function': 'off',
      'jsdoc/require-jsdoc': 'off',
    },
  },
  { files: ['**/*.mjs', '**/*.cjs'], ...tseslint.configs.disableTypeChecked },
  {
    files: ['**/*.cjs'],
    languageOptions: { sourceType: 'commonjs', globals: { module: 'writable' } },
  },
);
