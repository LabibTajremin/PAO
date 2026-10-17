import { Body, Controller, HttpCode, Inject, Post, Req, Res } from '@nestjs/common';
import { type Response } from 'express';
import { rateLimited } from '../../../../platform/http/api-error';
import { type ApiRequest } from '../../../../platform/http/api-request';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { Authenticated, Public } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { ClientIp, CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { CodeRateLimitedError, PhoneCodes } from '../../app/phone-codes';
import { PhoneSignIn } from '../../app/phone-sign-in';
import { Sessions } from '../../app/sessions';
import { CODE_TTL_MS, RESEND_AFTER_MS } from '../../domain/code';
import { REFRESH_TTL_MS } from '../../domain/session';
import { identityErrors } from './identity-errors';
import { refreshCookie, tokenPair } from './views';

type Schemas = components['schemas'];

const refreshCookieOf = (req: ApiRequest): string | undefined =>
  (req.cookies as Record<string, string | undefined>).pao_refresh;

/** Phone sign-in, token refresh and sign-out (C-01, P-01). */
@Controller('v1/auth')
@MapErrors(identityErrors)
export class AuthController {
  constructor(
    @Inject(PhoneCodes) private readonly codes: PhoneCodes,
    @Inject(PhoneSignIn) private readonly phoneSignIn: PhoneSignIn,
    @Inject(Sessions) private readonly sessions: Sessions,
  ) {}

  @Post('otp/request')
  @Public()
  @HttpCode(202)
  async requestOtp(
    @Body() body: Schemas['OtpRequest'],
    @ClientIp() clientIp: string | undefined,
  ): Promise<Schemas['OtpRequestAccepted']> {
    const purpose = body.purpose ?? 'login';
    try {
      await this.codes.send({ phone: body.phone, purpose, clientIp: clientIp ?? '' });
    } catch (err) {
      throw err instanceof CodeRateLimitedError
        ? rateLimited('RATE_LIMITED', err.retryAfterMs)
        : err;
    }
    return { expiresInSeconds: CODE_TTL_MS / 1000, resendAfterSeconds: RESEND_AFTER_MS / 1000 };
  }

  @Post('otp/verify')
  @Public()
  @HttpCode(200)
  async verifyOtp(@Body() body: Schemas['OtpVerifyRequest']): Promise<Schemas['TokenPair']> {
    return tokenPair(await this.phoneSignIn.verify(body), true);
  }

  /**
   * Mobile apps send the refresh token in the body; the admin web app relies on its
   * HttpOnly cookie and gets the new one back as a cookie.
   */
  @Post('refresh')
  @Public()
  @HttpCode(200)
  async refresh(
    @Body() body: Schemas['RefreshRequest'] | undefined,
    @Req() req: ApiRequest,
    @Res({ passthrough: true }) res: Response,
  ): Promise<Schemas['TokenPair']> {
    const cookie = body?.refreshToken === undefined ? refreshCookieOf(req) : undefined;
    const session = await this.sessions.refresh(body?.refreshToken ?? cookie ?? '');
    if (cookie !== undefined) {
      res.setHeader('Set-Cookie', refreshCookie(session.refreshToken, REFRESH_TTL_MS));
    }
    return tokenPair(session, cookie === undefined);
  }

  @Post('logout')
  @Authenticated()
  @HttpCode(204)
  async logout(
    @CurrentPrincipal() me: Principal,
    @Body() body: Schemas['LogoutRequest'] | undefined,
    @Req() req: ApiRequest,
    @Res({ passthrough: true }) res: Response,
  ): Promise<void> {
    await this.sessions.logout(me, body?.allDevices === true);
    if (refreshCookieOf(req) !== undefined) {
      res.setHeader('Set-Cookie', refreshCookie('', 0));
    }
  }
}
