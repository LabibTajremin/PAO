import { Controller, Get, Inject, Param } from '@nestjs/common';
import { type components } from '../../../../platform/http/openapi.gen';
import { MapErrors } from '../../../../platform/http/map-errors';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { ViewMedia } from '../../app/view-media';
import { mediaErrors } from './errors';

/** The admin document viewer; each view of a verification document is audited. */
@Controller('v1/admin/documents')
@MapErrors(mediaErrors)
@RequirePermission('verification:docs:view')
export class DocumentsController {
  constructor(@Inject(ViewMedia) private readonly views: ViewMedia) {}

  @Get(':mediaId/view-url')
  async viewUrl(
    @CurrentPrincipal() me: Principal,
    @Param('mediaId') id: string,
  ): Promise<components['schemas']['ViewUrl']> {
    const view = await this.views.viewUrl(id, { id: me.accountId, role: me.roles[0] ?? '' });
    return { url: view.url, expiresAt: view.expiresAt.toISOString() };
  }
}
