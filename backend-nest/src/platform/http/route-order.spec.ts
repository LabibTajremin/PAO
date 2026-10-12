import { Controller, Get, Module, Param } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { type Server } from 'node:http';
import { type AddressInfo } from 'node:net';
import { initWithOrderedRoutes, preferLiteralRoutes } from './route-order';

@Controller('v1/customer/providers')
class ProfileController {
  @Get(':providerId')
  profile(@Param('providerId') id: string): string {
    return `profile ${id}`;
  }
}

@Controller('v1/customer/providers')
class NearbyController {
  @Get('nearby')
  nearby(): string {
    return 'nearby';
  }
}

@Module({ controllers: [ProfileController, NearbyController] })
class ShadowingModule {}

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

  it('routes a literal path to its own handler in an app from NestFactory', async () => {
    const app = await NestFactory.create(ShadowingModule, { logger: false });
    await initWithOrderedRoutes(app);
    await app.listen(0, '127.0.0.1');
    const { port } = (app.getHttpServer() as Server).address() as AddressInfo;
    const get = (path: string) => fetch(`http://127.0.0.1:${port}${path}`).then((r) => r.text());
    expect(await get('/v1/customer/providers/nearby')).toBe('nearby');
    expect(await get('/v1/customer/providers/p1')).toBe('profile p1');
    await app.close();
  });
});
