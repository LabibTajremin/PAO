import { Module } from '@nestjs/common';
import {
  AdminBillingController,
  ProviderBillingController,
} from './adapter/http/billing.controller';

/** Merchant dues (ADR-0035): routes only; the behaviour lives in the .NET backend. */
@Module({ controllers: [ProviderBillingController, AdminBillingController] })
export class BillingModule {}
