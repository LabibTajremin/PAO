import { Body, Controller, HttpCode, Inject, Param, Post } from '@nestjs/common';
import { type components } from '../../../../platform/http/openapi.gen';
import { MapErrors } from '../../../../platform/http/map-errors';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { ConfirmUpload } from '../../app/confirm-upload';
import { CreateUpload, type Ticket } from '../../app/create-upload';
import { type MediaObject } from '../../domain/media';
import { mediaErrors } from './errors';

type Schemas = components['schemas'];

function ticketView(t: Ticket): Schemas['UploadTicket'] {
  return {
    mediaId: t.mediaId,
    uploadUrl: t.url,
    headers: { ...t.headers },
    expiresAt: t.expiresAt.toISOString(),
  };
}

function confirmedView(o: MediaObject): Schemas['MediaObject'] {
  return {
    id: o.id,
    purpose: o.purpose as Schemas['UploadPurpose'],
    contentType: o.contentType,
    sizeBytes: o.sizeBytes,
    status: 'confirmed',
  };
}

/** Customer uploads: avatars and complaint photos. */
@Controller('v1/customer/uploads')
@MapErrors(mediaErrors)
@RequirePermission('media:upload')
export class CustomerUploadsController {
  constructor(
    @Inject(CreateUpload) private readonly uploads: CreateUpload,
    @Inject(ConfirmUpload) private readonly confirmations: ConfirmUpload,
  ) {}

  @Post()
  @HttpCode(201)
  async create(
    @CurrentPrincipal() me: Principal,
    @Body() body: Schemas['UploadRequest'],
  ): Promise<Schemas['UploadTicket']> {
    return ticketView(await this.uploads.create(me.accountId, 'customer', body));
  }

  @Post(':mediaId/confirm')
  @HttpCode(200)
  async confirm(
    @CurrentPrincipal() me: Principal,
    @Param('mediaId') id: string,
  ): Promise<Schemas['MediaObject']> {
    return confirmedView(await this.confirmations.confirm(me.accountId, id));
  }
}

/** Provider uploads, verification documents included. */
@Controller('v1/provider/uploads')
@MapErrors(mediaErrors)
@RequirePermission('media:upload')
export class ProviderUploadsController {
  constructor(
    @Inject(CreateUpload) private readonly uploads: CreateUpload,
    @Inject(ConfirmUpload) private readonly confirmations: ConfirmUpload,
  ) {}

  @Post()
  @HttpCode(201)
  async create(
    @CurrentPrincipal() me: Principal,
    @Body() body: Schemas['UploadRequest'],
  ): Promise<Schemas['UploadTicket']> {
    return ticketView(await this.uploads.create(me.accountId, 'provider', body));
  }

  @Post(':mediaId/confirm')
  @HttpCode(200)
  async confirm(
    @CurrentPrincipal() me: Principal,
    @Param('mediaId') id: string,
  ): Promise<Schemas['MediaObject']> {
    return confirmedView(await this.confirmations.confirm(me.accountId, id));
  }
}
