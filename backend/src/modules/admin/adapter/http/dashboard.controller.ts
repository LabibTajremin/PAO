import { Controller, Get } from '@nestjs/common';
import { type components } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { ReadDashboard } from '../../app/read-dashboard';

/** The admin home numbers (A-09). */
@Controller('v1/admin/dashboard')
export class DashboardController {
  constructor(private readonly dashboard: ReadDashboard) {}

  @Get()
  @RequirePermission('dashboard:read')
  async get(): Promise<components['schemas']['Dashboard']> {
    const d = await this.dashboard.execute();
    return {
      providersByStatus: d.providersByStatus,
      providersByLevel: d.providersByLevel,
      bookingsPerDay: d.bookingsPerDay.map((day) => ({ ...day })),
      completionRate: d.completionRate,
      openComplaints: d.openComplaints,
      pendingVerifications: d.pendingVerifications,
      generatedAt: d.generatedAt.toISOString(),
    };
  }
}
