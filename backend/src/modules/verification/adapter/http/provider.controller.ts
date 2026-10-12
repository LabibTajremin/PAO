import { Body, Controller, Get, HttpCode, Post, Put } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { type EnrolmentStatus } from '../../../provider/contract/enrolment';
import { SaveDocuments } from '../../app/documents';
import { ProviderStatus } from '../../app/status';
import { verificationErrors } from './error-map';
import { statusView } from './views';

type Schemas = components['schemas'];
type Step = Promise<Schemas['EnrolmentStatus']>;

function stepView(s: EnrolmentStatus): Schemas['EnrolmentStatus'] {
  return { ...s, steps: [...s.steps] };
}

/** The document steps of the enrolment wizard (M08–M11) and submission. */
@Controller('v1/provider/enrolment')
@MapErrors(verificationErrors)
export class DocumentsController {
  constructor(
    private readonly documents: SaveDocuments,
    private readonly status: ProviderStatus,
  ) {}

  @Put('nid')
  @RequirePermission('provider:manage:own')
  async nid(@CurrentPrincipal() me: Principal, @Body() b: Schemas['NidInput']): Step {
    const s = await this.documents.saveNid(
      me.accountId,
      b.nidNumber,
      b.frontMediaId,
      b.backMediaId,
    );
    return stepView(s);
  }

  @Put('selfie')
  @RequirePermission('provider:manage:own')
  async selfie(@CurrentPrincipal() me: Principal, @Body() b: Schemas['SelfieInput']): Step {
    return stepView(await this.documents.saveSelfie(me.accountId, b.mediaId));
  }

  @Put('police-clearance')
  @RequirePermission('provider:manage:own')
  async policeClearance(
    @CurrentPrincipal() me: Principal,
    @Body() b: Schemas['PoliceClearanceInput'],
  ): Step {
    const issued = new Date(b.issueDate);
    return stepView(await this.documents.savePoliceClearance(me.accountId, b.mediaId, issued));
  }

  @Put('skill-proof')
  @RequirePermission('provider:manage:own')
  async skillProof(@CurrentPrincipal() me: Principal, @Body() b: Schemas['SkillProofInput']): Step {
    return stepView(await this.documents.saveSkillProof(me.accountId, b.mediaIds));
  }

  @Post('submit')
  @RequirePermission('verification:submit')
  @HttpCode(200)
  async submit(@CurrentPrincipal() me: Principal): Promise<Schemas['VerificationStatus']> {
    return statusView(await this.status.submit(me.accountId));
  }
}

/** The provider's verification screen (M14/P-03). */
@Controller('v1/provider/verification')
@MapErrors(verificationErrors)
export class StatusController {
  constructor(private readonly status: ProviderStatus) {}

  @Get()
  @RequirePermission('provider:manage:own')
  async get(@CurrentPrincipal() me: Principal): Promise<Schemas['VerificationStatus']> {
    return statusView(await this.status.status(me.accountId));
  }
}
