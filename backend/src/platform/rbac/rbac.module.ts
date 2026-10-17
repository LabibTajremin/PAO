import { Global, Module } from '@nestjs/common';
import { PostgresRbacSource, RBAC_SOURCE, RbacChecker } from './rbac';

/**
 * Provides the {@link RbacChecker}. Grants are read from the identity schema; the
 * identity module changes them and bumps the version through the same checker.
 */
@Global()
@Module({
  providers: [RbacChecker, { provide: RBAC_SOURCE, useClass: PostgresRbacSource }],
  exports: [RbacChecker],
})
export class RbacModule {}
