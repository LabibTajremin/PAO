import { Body, Controller, Get, HttpCode, Param, Post, Put } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { ManagePresence } from '../../app/presence';
import { ProviderProfiles, PublicProfiles } from '../../app/profile';
import { providerErrors } from './error-map';
import { presenceView, profileView, publicProfileView } from './views';

type Schemas = components['schemas'];

/** The provider's own profile (M28). */
@Controller('v1/provider/profile')
@MapErrors(providerErrors)
@RequirePermission('provider:manage:own')
export class ProfileController {
  constructor(private readonly profiles: ProviderProfiles) {}

  @Get()
  async get(@CurrentPrincipal() me: Principal): Promise<Schemas['ProviderProfile']> {
    return profileView(await this.profiles.own(me.accountId));
  }

  @Put()
  async update(
    @CurrentPrincipal() me: Principal,
    @Body() b: Schemas['ProviderProfileUpdate'],
  ): Promise<Schemas['ProviderProfile']> {
    const p = await this.profiles.update(me.accountId, {
      bio: b.bio ?? '',
      photoMediaId: b.photoMediaId ?? null,
      language: b.language,
    });
    return profileView(p);
  }
}

/** Going online, staying online and going offline (PRD §6.1). */
@Controller('v1/provider/presence')
@MapErrors(providerErrors)
@RequirePermission('provider:manage:own')
export class PresenceController {
  constructor(private readonly presence: ManagePresence) {}

  @Post('online')
  @HttpCode(200)
  async online(
    @CurrentPrincipal() me: Principal,
    @Body() b: Schemas['HeartbeatInput'],
  ): Promise<Schemas['PresenceState']> {
    await this.presence.goOnline(me.accountId, b.location);
    return presenceView(true);
  }

  @Post('heartbeat')
  @HttpCode(200)
  async heartbeat(
    @CurrentPrincipal() me: Principal,
    @Body() b: Schemas['HeartbeatInput'],
  ): Promise<Schemas['PresenceState']> {
    await this.presence.heartbeat(me.accountId, b.location);
    return presenceView(true);
  }

  @Post('offline')
  @HttpCode(200)
  async offline(@CurrentPrincipal() me: Principal): Promise<Schemas['PresenceState']> {
    await this.presence.goOffline(me.accountId, 'provider');
    return presenceView(false);
  }
}

/** A provider as customers see them (C11). */
@Controller('v1/customer/providers')
@MapErrors(providerErrors)
export class PublicProfileController {
  constructor(private readonly profiles: PublicProfiles) {}

  @Get(':providerId')
  @RequirePermission('provider:browse')
  async get(
    @CurrentPrincipal() me: Principal,
    @Param('providerId') id: string,
  ): Promise<Schemas['ProviderPublicProfile']> {
    return publicProfileView(await this.profiles.get(me.accountId, id));
  }
}
