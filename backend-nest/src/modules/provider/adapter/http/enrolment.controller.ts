import { Body, Controller, Get, HttpCode, Post, Put } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { SaveEmergencyContact } from '../../app/emergency-contact';
import { Enrolment } from '../../app/enrolment';
import { providerErrors } from './error-map';
import { enrolmentView } from './views';

type Schemas = components['schemas'];
type Status = Promise<Schemas['EnrolmentStatus']>;

/** The profile steps of the enrolment wizard (M05–M13). */
@Controller('v1/provider/enrolment')
@MapErrors(providerErrors)
@RequirePermission('provider:manage:own')
export class EnrolmentController {
  constructor(
    private readonly enrolment: Enrolment,
    private readonly contact: SaveEmergencyContact,
  ) {}

  @Get()
  async get(@CurrentPrincipal() me: Principal): Status {
    return enrolmentView(await this.enrolment.progress(me.accountId));
  }

  @Put('personal')
  async personal(
    @CurrentPrincipal() me: Principal,
    @Body() b: Schemas['PersonalInfoInput'],
  ): Status {
    const p = await this.enrolment.savePersonal(me.accountId, {
      ...b,
      dateOfBirth: new Date(b.dateOfBirth),
      bio: b.bio ?? '',
    });
    return enrolmentView(p);
  }

  @Put('services')
  async services(@CurrentPrincipal() me: Principal, @Body() b: Schemas['ServicesInput']): Status {
    const p = await this.enrolment.saveServices(me.accountId, b.serviceIds, b.experienceYears);
    return enrolmentView(p);
  }

  @Put('area')
  async area(@CurrentPrincipal() me: Principal, @Body() b: Schemas['ServiceAreaInput']): Status {
    const home = { lat: b.homeBase.lat, lng: b.homeBase.lng };
    return enrolmentView(await this.enrolment.saveArea(me.accountId, home, b.workingRadiusM));
  }

  @Put('emergency-contact')
  async emergencyContact(
    @CurrentPrincipal() me: Principal,
    @Body() b: Schemas['EmergencyContactInput'],
  ): Status {
    const c = { name: b.name, relation: b.relation, phone: b.phone };
    return enrolmentView(await this.contact.save(me.accountId, c));
  }

  @Post('emergency-contact/verify')
  @HttpCode(200)
  async verifyEmergencyContact(
    @CurrentPrincipal() me: Principal,
    @Body() b: Schemas['EmergencyContactVerifyInput'],
  ): Status {
    return enrolmentView(await this.contact.verify(me.accountId, b.code));
  }

  @Put('code-of-conduct')
  async codeOfConduct(
    @CurrentPrincipal() me: Principal,
    @Body() b: Schemas['CodeOfConductInput'],
  ): Status {
    const p = await this.enrolment.acceptCodeOfConduct(me.accountId, b.version, b.accepted);
    return enrolmentView(p);
  }
}
