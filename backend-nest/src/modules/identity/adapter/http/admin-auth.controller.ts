import { Body, Controller, HttpCode, Inject, Post, Res } from '@nestjs/common';
import { type Response } from 'express';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { Authenticated, Public } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { AdminSignIn } from '../../app/admin-sign-in';
import { AdminTotp } from '../../app/admin-totp';
import { CHALLENGE_TTL_MS } from '../../domain/admin';
import { REFRESH_TTL_MS } from '../../domain/session';
import { identityErrors } from './identity-errors';
import { refreshCookie, tokenPair } from './views';

type Schemas = components['schemas'];

/** Admin email + password + TOTP sign-in and password change (A-01). */
@Controller('v1/auth/admin')
@MapErrors(identityErrors)
export class AdminAuthController {
  constructor(
    @Inject(AdminSignIn) private readonly adminSignIn: AdminSignIn,
    @Inject(AdminTotp) private readonly adminTotp: AdminTotp,
  ) {}

  @Post('login')
  @Public()
  @HttpCode(200)
  async adminLogin(
    @Body() body: Schemas['AdminLoginRequest'],
  ): Promise<Schemas['AdminLoginChallenge']> {
    const ch = await this.adminSignIn.login(body.email, body.password);
    return {
      challengeId: ch.id,
      expiresInSeconds: CHALLENGE_TTL_MS / 1000,
      ...(ch.enrolSecret === ''
        ? {}
        : { totpEnrolment: { secret: ch.enrolSecret, otpauthUrl: ch.enrolUrl } }),
      mustChangePassword: ch.mustChangePassword,
    };
  }

  @Post('totp')
  @Public()
  @HttpCode(200)
  async adminVerifyTotp(
    @Body() body: Schemas['AdminTotpRequest'],
    @Res({ passthrough: true }) res: Response,
  ): Promise<Schemas['TokenPair']> {
    const session = await this.adminTotp.verify(body.challengeId, body.code);
    res.setHeader('Set-Cookie', refreshCookie(session.refreshToken, REFRESH_TTL_MS));
    return tokenPair(session, false);
  }

  @Post('password')
  @Authenticated()
  @HttpCode(204)
  async changeAdminPassword(
    @CurrentPrincipal() me: Principal,
    @Body() body: Schemas['AdminPasswordChange'],
  ): Promise<void> {
    await this.adminSignIn.changePassword(me.accountId, body.currentPassword, body.newPassword);
  }
}
