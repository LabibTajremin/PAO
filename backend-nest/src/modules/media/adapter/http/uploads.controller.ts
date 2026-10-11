import { Body, Controller, HttpCode, Inject, Param, Post } from '@nestjs/common';
import { type components } from '../../../../platform/http/openapi.gen';
import { MapErrors } from '../../../../platform/http/map-errors';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { ConfirmUpload } from '../../app/confirm-upload';
import { CreateUpload } from '../../app/create-upload';
import { type Uploader } from '../../domain/media';
import { mediaErrors } from './errors';

type Schemas = components['schemas'];

/** Upload and confirm, the same for both apps; only the purposes allowed differ. */
abstract class UploadsController {
  protected abstract readonly uploader: Uploader;

  constructor(
    private readonly uploads: CreateUpload,
    private readonly confirmations: ConfirmUpload,
  ) {}

  @Post()
  @HttpCode(201)
  async create(
    @CurrentPrincipal() me: Principal,
    @Body() body: Schemas['UploadRequest'],
  ): Promise<Schemas['UploadTicket']> {
    const t = await this.uploads.create(me.accountId, this.uploader, body);
    return {
      mediaId: t.mediaId,
      uploadUrl: t.url,
      headers: { ...t.headers },
      expiresAt: t.expiresAt.toISOString(),
    };
  }

  @Post(':mediaId/confirm')
  @HttpCode(200)
  async confirm(
    @CurrentPrincipal() me: Principal,
    @Param('mediaId') id: string,
  ): Promise<Schemas['MediaObject']> {
    const o = await this.confirmations.confirm(me.accountId, id);
    return {
      id: o.id,
      purpose: o.purpose as Schemas['UploadPurpose'],
      contentType: o.contentType,
      sizeBytes: o.sizeBytes,
      status: 'confirmed',
    };
  }
}

/** Customer uploads: avatars and complaint photos. */
@Controller('v1/customer/uploads')
@MapErrors(mediaErrors)
@RequirePermission('media:upload')
export class CustomerUploadsController extends UploadsController {
  protected readonly uploader = 'customer';

  constructor(
    @Inject(CreateUpload) uploads: CreateUpload,
    @Inject(ConfirmUpload) confirmations: ConfirmUpload,
  ) {
    super(uploads, confirmations);
  }
}

/** Provider uploads, verification documents included. */
@Controller('v1/provider/uploads')
@MapErrors(mediaErrors)
@RequirePermission('media:upload')
export class ProviderUploadsController extends UploadsController {
  protected readonly uploader = 'provider';

  constructor(
    @Inject(CreateUpload) uploads: CreateUpload,
    @Inject(ConfirmUpload) confirmations: ConfirmUpload,
  ) {
    super(uploads, confirmations);
  }
}
