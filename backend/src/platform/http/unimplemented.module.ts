import { All, Controller, Module } from '@nestjs/common';
import { NOT_IMPLEMENTED } from './api-error';
import { PermissionFromSpec } from './permissions';

/**
 * Answers 501 NOT_IMPLEMENTED for spec operations no module serves yet, after the same
 * authentication, permission, rate-limit and validation checks a real route gets.
 */
@Controller()
export class UnimplementedController {
  @All('{*path}')
  @PermissionFromSpec()
  notImplemented(): never {
    throw NOT_IMPLEMENTED;
  }
}

/**
 * Holds the catch-all route. The composition root imports it last, because Nest
 * registers routes in module order and the catch-all must come after every module.
 */
@Module({ controllers: [UnimplementedController] })
export class UnimplementedModule {}
