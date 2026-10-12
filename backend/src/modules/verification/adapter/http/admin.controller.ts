import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { encodeCursor } from '../../../../platform/http/cursor';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components, type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { ReviewItems } from '../../app/review';
import { verificationErrors } from './error-map';
import { reviewView } from './review-view';
import { pageOf, queueView } from './views';

type Schemas = components['schemas'];
type Review = Promise<Schemas['VerificationReview']>;
type QueueQuery = NonNullable<operations['listVerificationQueue']['parameters']['query']>;

/** The verification review queue and per-item decisions (A-03, A06). */
@Controller('v1/admin/verifications')
@MapErrors(verificationErrors)
@RequirePermission('verification:review')
export class ReviewController {
  constructor(private readonly reviews: ReviewItems) {}

  @Get()
  async queue(@Query() q: QueueQuery): Promise<Schemas['VerificationQueue']> {
    const { size, page } = pageOf(q);
    const filter = { itemType: q.itemType ?? null, serviceId: q.serviceId ?? null };
    const rows = await this.reviews.queue(filter, page);
    const shown = rows.slice(0, size);
    const last = shown.at(-1);
    const items = shown.map(queueView);
    if (rows.length > size && last) {
      return {
        items,
        nextCursor: encodeCursor({ createdAt: last.submittedAt, id: last.providerId }),
      };
    }
    return { items };
  }

  @Get(':providerId')
  async get(@Param('providerId') id: string): Review {
    return reviewView(await this.reviews.review(id));
  }

  @Post(':providerId/items/:itemType/approve')
  @HttpCode(200)
  async approve(
    @CurrentPrincipal() me: Principal,
    @Param('providerId') providerId: string,
    @Param('itemType') item: string,
  ): Review {
    const d = { providerId, item, actor: me.accountId, approve: true, reason: '' };
    return reviewView(await this.reviews.decide(d));
  }

  @Post(':providerId/items/:itemType/reject')
  @HttpCode(200)
  async reject(
    @CurrentPrincipal() me: Principal,
    @Param('providerId') providerId: string,
    @Param('itemType') item: string,
    @Body() b: Schemas['StatusReason'],
  ): Review {
    const d = { providerId, item, actor: me.accountId, approve: false, reason: b.reason };
    return reviewView(await this.reviews.decide(d));
  }
}
