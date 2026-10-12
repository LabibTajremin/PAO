import { preferLiteralRoutes } from './route-order';

function layer(path?: string) {
  const pattern =
    path === undefined ? undefined : new RegExp(`^${path.replace(/:\w+/g, '[^/]+')}$`);
  return {
    name: path ?? 'middleware',
    ...(path === undefined ? {} : { route: { path } }),
    match: (p: string) => pattern?.test(p) ?? true,
  };
}

describe('preferLiteralRoutes', () => {
  it('moves a literal route ahead of a parameter route that shadows it', () => {
    const stack = [
      layer(),
      layer('/v1/customer/providers/:providerId'),
      layer('/v1/customer/providers/nearby'),
      layer('/v1/other'),
      layer('/v1/other'),
    ];
    preferLiteralRoutes(stack);
    expect(stack.map((l) => l.name)).toEqual([
      'middleware',
      '/v1/customer/providers/nearby',
      '/v1/customer/providers/:providerId',
      '/v1/other',
      '/v1/other',
    ]);
  });
});
