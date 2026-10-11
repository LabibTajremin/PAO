import { type DynamicModule, Module } from '@nestjs/common';

@Module({})
class StandInModule {}

/** A global module that provides fixed values for `tokens`, standing in for a real module. */
export function standIn(values: ReadonlyMap<string | symbol, unknown>): DynamicModule {
  const providers = [...values].map(([provide, useValue]) => ({ provide, useValue }));
  return {
    module: StandInModule,
    global: true,
    providers,
    exports: [...values.keys()],
  };
}
