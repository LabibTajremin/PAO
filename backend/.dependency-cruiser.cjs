// Module boundary rules (PRD §9.3, docs/build/02-architecture.md §1): a module reaches
// another module only through its contract/, platform/ never depends on modules, and a
// domain/ depends on nothing but its own domain and Node built-ins.
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    {
      name: 'module-reaches-only-contracts',
      severity: 'error',
      comment: 'A module may use another module only through modules/<other>/contract.',
      from: { path: '^src/modules/([^/]+)/' },
      to: {
        path: '^src/modules/([^/]+)/',
        pathNot: ['^src/modules/$1/', '^src/modules/[^/]+/contract/'],
      },
    },
    {
      name: 'platform-is-module-agnostic',
      severity: 'error',
      from: { path: '^src/platform/' },
      to: { path: '^src/(modules|app)/' },
    },
    {
      name: 'domain-is-pure',
      severity: 'error',
      comment: 'domain/ imports only its own domain/ and Node built-ins.',
      from: { path: '^src/modules/([^/]+)/domain/', pathNot: '\\.spec\\.ts$' },
      to: {
        pathNot: ['^src/modules/$1/domain/'],
        dependencyTypesNot: ['core'],
      },
    },
    {
      name: 'contract-is-self-contained',
      severity: 'error',
      comment: 'contract/ imports only contracts and platform types.',
      from: { path: '^src/modules/[^/]+/contract/' },
      to: {
        pathNot: ['^src/modules/[^/]+/contract/', '^src/platform/'],
        dependencyTypesNot: ['core', 'npm'],
      },
    },
    {
      name: 'no-circular',
      severity: 'error',
      from: {},
      to: { circular: true },
    },
    {
      name: 'no-orphans',
      severity: 'error',
      from: {
        orphan: true,
        pathNot: [
          '\\.d\\.ts$',
          '(^|/)\\.[^/]+\\.(js|cjs|mjs|ts|json)$',
          '\\.(spec|int-spec)\\.ts$',
          '^src/(main|worker|migrate)\\.ts$',
        ],
      },
      to: {},
    },
    {
      name: 'no-unresolvable',
      severity: 'error',
      from: {},
      to: { couldNotResolve: true },
    },
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    exclude: { path: '(^|/)(sqlc)/|\\.gen\\.ts$' },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: 'tsconfig.json' },
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default'],
    },
  },
};
