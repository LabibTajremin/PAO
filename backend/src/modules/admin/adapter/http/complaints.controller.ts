import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { decodeCursor, pageSize } from '../../../../platform/http/cursor';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components, type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { ReportProblem } from '../../app/report-problem';
import { WorkComplaints } from '../../app/work-complaints';
import { type ReporterRole } from '../../domain/complaint';
import { adminErrors } from './error-map';
import { complaintView, page } from './views';

type Schemas = components['schemas'];
type Complaint = Schemas['Complaint'];
type QueueQuery = NonNullable<operations['listComplaints']['parameters']['query']>;

/** The support queue (A-07). */
@Controller('v1/admin/complaints')
@MapErrors(adminErrors)
export class ComplaintsController {
  constructor(private readonly complaints: WorkComplaints) {}

  @Get()
  @RequirePermission('complaint:manage')
  async list(@Query() q: QueueQuery): Promise<Schemas['ComplaintList']> {
    const cursor = decodeCursor(q.cursor);
    const size = pageSize(q.limit);
    const rows = await this.complaints.list({
      status: q.status ?? null,
      assigneeId: q.assigneeId ?? null,
      after: cursor ? { createdAt: new Date(cursor.createdAt), id: cursor.id } : null,
      limit: size + 1,
    });
    return page(rows, size, complaintView);
  }

  @Get(':complaintId')
  @RequirePermission('complaint:manage')
  async get(@Param('complaintId') id: string): Promise<Complaint> {
    return complaintView(await this.complaints.get(id));
  }

  @Post(':complaintId/assign')
  @RequirePermission('complaint:manage')
  @HttpCode(200)
  async assign(
    @Param('complaintId') id: string,
    @Body() body: Schemas['ComplaintAssignInput'],
  ): Promise<Complaint> {
    return complaintView(await this.complaints.assign(id, body.assigneeId));
  }

  @Post(':complaintId/comments')
  @RequirePermission('complaint:manage')
  async comment(
    @CurrentPrincipal() me: Principal,
    @Param('complaintId') id: string,
    @Body() body: Schemas['ComplaintCommentInput'],
  ): Promise<Complaint> {
    return complaintView(await this.complaints.comment(id, me.accountId, body.body));
  }

  @Post(':complaintId/resolve')
  @RequirePermission('complaint:manage')
  @HttpCode(200)
  async resolve(
    @CurrentPrincipal() me: Principal,
    @Param('complaintId') id: string,
    @Body() body: Schemas['ComplaintResolveInput'],
  ): Promise<Complaint> {
    const c = await this.complaints.resolve(id, me.accountId, body.resolution, body.verified);
    return complaintView(c);
  }
}

/** Files a report from either app (C-14). */
async function report(
  problems: ReportProblem,
  role: ReporterRole,
  args: { me: Principal; bookingId: string; body: Schemas['ComplaintInput'] },
): Promise<Complaint> {
  const c = await problems.execute({
    bookingId: args.bookingId,
    reporterId: args.me.accountId,
    reporterRole: role,
    reason: args.body.reason,
    description: args.body.description,
    photos: args.body.photoMediaIds ?? [],
  });
  return complaintView(c);
}

/** A customer reports a problem with a booking. */
@Controller('v1/customer/bookings')
@MapErrors(adminErrors)
export class CustomerReportsController {
  constructor(private readonly problems: ReportProblem) {}

  @Post(':bookingId/reports')
  @RequirePermission('complaint:create')
  create(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') bookingId: string,
    @Body() body: Schemas['ComplaintInput'],
  ): Promise<Complaint> {
    return report(this.problems, 'customer', { me, bookingId, body });
  }
}

/** A provider reports a problem with a job. */
@Controller('v1/provider/jobs')
@MapErrors(adminErrors)
export class ProviderReportsController {
  constructor(private readonly problems: ReportProblem) {}

  @Post(':bookingId/reports')
  @RequirePermission('complaint:create')
  create(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') bookingId: string,
    @Body() body: Schemas['ComplaintInput'],
  ): Promise<Complaint> {
    return report(this.problems, 'provider', { me, bookingId, body });
  }
}
