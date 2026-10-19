import { Controller, Get, Post } from '@nestjs/common';
import { NOT_IMPLEMENTED } from '../../../../platform/http/api-error';
import { RequirePermission } from '../../../../platform/http/permissions';

/**
 * The merchant's billing operations (ADR-0035). Billing is built only in the .NET backend
 * (P17), which replaces this one; NestJS declares the routes with their spec permissions so
 * RBAC and the contract checks cover them, and answers 501.
 */
@Controller('v1/provider/billing')
@RequirePermission('provider:manage:own')
export class ProviderBillingController {
  @Get('summary')
  summary(): never {
    throw NOT_IMPLEMENTED;
  }

  @Get('ledger')
  ledger(): never {
    throw NOT_IMPLEMENTED;
  }

  @Get('payments')
  payments(): never {
    throw NOT_IMPLEMENTED;
  }

  @Post('payments')
  submit(): never {
    throw NOT_IMPLEMENTED;
  }
}

/** The admin console's payment review (ADR-0035 §4); .NET only, see above. */
@Controller('v1/admin/billing')
@RequirePermission('billing:manage')
export class AdminBillingController {
  @Get('payments')
  payments(): never {
    throw NOT_IMPLEMENTED;
  }

  @Post('payments/:submissionId/confirm')
  confirm(): never {
    throw NOT_IMPLEMENTED;
  }

  @Post('payments/:submissionId/reject')
  reject(): never {
    throw NOT_IMPLEMENTED;
  }

  @Get('merchants/:providerId/ledger')
  ledger(): never {
    throw NOT_IMPLEMENTED;
  }
}
