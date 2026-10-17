import { Body, Controller, Get, Param, Post, HttpCode, Query } from '@nestjs/common';
import { encodeCursor } from '../../../../platform/http/cursor';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components, type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { Level2Sessions } from '../../app/level2';
import { verificationErrors } from './error-map';
import { pageOf, sessionView } from './views';

type Schemas = components['schemas'];
type SessionView = Promise<Schemas['Level2Session']>;
type ListQuery = NonNullable<operations['listLevel2Sessions']['parameters']['query']>;

/** Level 2 sessions (PRD §6.3, A-04). */
@Controller('v1/admin/level2-sessions')
@MapErrors(verificationErrors)
@RequirePermission('level2:manage')
export class Level2Controller {
  constructor(private readonly sessions: Level2Sessions) {}

  @Get()
  async list(@Query() q: ListQuery): Promise<Schemas['Level2SessionList']> {
    const { size, page } = pageOf(q);
    const filter = { providerId: q.providerId ?? null, status: q.status ?? null };
    const rows = await this.sessions.list(filter, page);
    const shown = rows.slice(0, size);
    const last = shown.at(-1);
    const items = shown.map(sessionView);
    return rows.length > size && last ? { items, nextCursor: encodeCursor(last) } : { items };
  }

  @Post()
  async schedule(@Body() b: Schemas['Level2SessionInput']): SessionView {
    const s = await this.sessions.schedule({ ...b, at: new Date(b.scheduledAt) });
    return sessionView(s);
  }

  @Get(':sessionId')
  async get(@Param('sessionId') id: string): SessionView {
    return sessionView(await this.sessions.get(id));
  }

  @Post(':sessionId/result')
  @HttpCode(200)
  async record(
    @CurrentPrincipal() me: Principal,
    @Param('sessionId') id: string,
    @Body() b: Schemas['Level2ResultInput'],
  ): SessionView {
    const s = await this.sessions.record(id, me.accountId, {
      result: b.result,
      checklist: b.checklist,
      notes: b.notes ?? '',
      visitLat: b.visitLocation?.lat ?? null,
      visitLng: b.visitLocation?.lng ?? null,
      photos: b.photoMediaIds ?? [],
    });
    return sessionView(s);
  }
}
