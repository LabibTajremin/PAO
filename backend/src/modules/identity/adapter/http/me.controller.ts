import { Body, Controller, Delete, Get, HttpCode, Inject } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { Authenticated } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { AccountDeletion } from '../../app/delete-account';
import { MyAccount } from '../../app/my-account';
import { identityErrors } from './identity-errors';
import { accountView } from './views';

type Schemas = components['schemas'];

/** The signed-in account: profile, grants and deletion. */
@Controller('v1/me')
@MapErrors(identityErrors)
export class MeController {
  constructor(
    @Inject(MyAccount) private readonly me: MyAccount,
    @Inject(AccountDeletion) private readonly deletion: AccountDeletion,
  ) {}

  @Get()
  @Authenticated()
  async getMe(@CurrentPrincipal() p: Principal): Promise<Schemas['Account']> {
    return accountView(await this.me.get(p.accountId));
  }

  @Get('permissions')
  @Authenticated()
  async getMyPermissions(@CurrentPrincipal() p: Principal): Promise<Schemas['MyPermissions']> {
    const v = await this.me.permissions(p.accountId);
    return {
      roles: v.roles as Schemas['Role'][],
      permissions: [...v.permissions],
      screens: [...v.screens],
      providerGate: v.providerGate,
    };
  }

  @Delete()
  @Authenticated()
  @HttpCode(204)
  async deleteMe(
    @CurrentPrincipal() p: Principal,
    @Body() body: Schemas['DeleteAccountRequest'],
  ): Promise<void> {
    await this.deletion.delete(p, body.code);
  }
}
