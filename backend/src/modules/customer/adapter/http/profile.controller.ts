import { Body, Controller, Get, Put } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { CustomerProfiles, type Profile } from '../../app/profiles';
import { customerErrors } from './error-map';

type ProfileView = components['schemas']['CustomerProfile'];

function profileView(p: Profile): ProfileView {
  return {
    id: p.id,
    name: p.name,
    language: p.language as ProfileView['language'],
    phone: p.phone,
    ...(p.photoUrl === '' ? {} : { photoUrl: p.photoUrl }),
  };
}

/** The customer's own profile (C-01). */
@Controller('v1/customer/profile')
@MapErrors(customerErrors)
export class CustomerProfileController {
  constructor(private readonly profiles: CustomerProfiles) {}

  @Get()
  @RequirePermission('profile:manage:own')
  async get(@CurrentPrincipal() me: Principal): Promise<ProfileView> {
    return profileView(await this.profiles.profile(me.accountId));
  }

  @Put()
  @RequirePermission('profile:manage:own')
  async update(
    @CurrentPrincipal() me: Principal,
    @Body() body: components['schemas']['CustomerProfileUpdate'],
  ): Promise<ProfileView> {
    const saved = await this.profiles.save(me.accountId, {
      name: body.name,
      language: body.language,
      photoMediaId: body.photoMediaId ?? null,
    });
    return profileView(saved);
  }
}
