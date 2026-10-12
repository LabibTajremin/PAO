import { Global, Module } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../../platform/config/app-config';
import { ID_GENERATOR, type IdGenerator } from '../../platform/ids/id-generator';
import { LOGGER, type Logger } from '../../platform/logging/logger';
import { ADMIN_SEEDER } from '../../platform/seeding/seeders';
import { SMS_CAPTURE } from '../../platform/testing/test-hooks';
import { AdminAuthController } from './adapter/http/admin-auth.controller';
import { AuthController } from './adapter/http/auth.controller';
import { AdminUsersController, RolesController } from './adapter/http/admin-users.controller';
import { MeController } from './adapter/http/me.controller';
import { IdentityAdminSeeder, InProcessIdentityService } from './adapter/inproc/identity-service';
import { VerificationLevels } from './adapter/inproc/verification-levels';
import { PostgresIdentityRepository } from './adapter/postgres/postgres-identity-repository';
import {
  RedisChallengeStore,
  RedisCodeStore,
  RedisSendThrottle,
  RedisSessionStore,
} from './adapter/redis/redis-stores';
import {
  CapturedSms,
  ConsoleSms,
  SSL_WIRELESS_ENDPOINT,
  SslWirelessSms,
} from './adapter/sms/sms-senders';
import { AccessTokens } from './app/access-tokens';
import { AccountStatusChanger } from './app/account-status';
import { AdminSignIn } from './app/admin-sign-in';
import { AdminTotp } from './app/admin-totp';
import { AdminUsers } from './app/admin-users';
import { AccountDeletion } from './app/delete-account';
import { MyAccount } from './app/my-account';
import { PhoneCodes } from './app/phone-codes';
import { PhoneAccounts, PhoneSignIn } from './app/phone-sign-in';
import { RoleEditor } from './app/role-editor';
import { Sessions } from './app/sessions';
import { IDENTITY_SERVICE } from './contract';
import { IDENTITY_REPOSITORY } from './port/identity-repository';
import { LEVEL_READER, SMS_SENDER } from './port/outside-world';
import {
  CHALLENGE_STORE,
  CODE_STORE,
  SEND_THROTTLE,
  SESSION_STORE,
} from './port/short-lived-state';

function smsSender(config: AppConfig, capture: CapturedSms, log: Logger, ids: IdGenerator) {
  if (config.appEnv === 'test') {
    return capture;
  }
  if (config.smsAdapter === 'sslwireless') {
    const { apiToken, sid } = config.sslWireless;
    return new SslWirelessSms(
      { endpoint: SSL_WIRELESS_ENDPOINT, apiToken, sid, timeoutMs: 10_000 },
      ids,
    );
  }
  return new ConsoleSms(log);
}

/**
 * Accounts, phone and admin sign-in, sessions, roles and the role editor. Other modules
 * reach it only through {@link IDENTITY_SERVICE}.
 */
@Global()
@Module({
  controllers: [
    AuthController,
    AdminAuthController,
    MeController,
    AdminUsersController,
    RolesController,
  ],
  providers: [
    PhoneCodes,
    PhoneAccounts,
    PhoneSignIn,
    AccessTokens,
    Sessions,
    AdminSignIn,
    AdminTotp,
    AccountDeletion,
    AdminUsers,
    MyAccount,
    AccountStatusChanger,
    RoleEditor,
    CapturedSms,
    { provide: IDENTITY_REPOSITORY, useClass: PostgresIdentityRepository },
    { provide: CODE_STORE, useClass: RedisCodeStore },
    { provide: SEND_THROTTLE, useClass: RedisSendThrottle },
    { provide: SESSION_STORE, useClass: RedisSessionStore },
    { provide: CHALLENGE_STORE, useClass: RedisChallengeStore },
    { provide: LEVEL_READER, useClass: VerificationLevels },
    {
      provide: SMS_SENDER,
      inject: [APP_CONFIG, CapturedSms, LOGGER, ID_GENERATOR],
      useFactory: smsSender,
    },
    {
      provide: SMS_CAPTURE,
      inject: [APP_CONFIG, CapturedSms],
      useFactory: (config: AppConfig, capture: CapturedSms) =>
        config.appEnv === 'test' ? capture : undefined,
    },
    { provide: IDENTITY_SERVICE, useClass: InProcessIdentityService },
    { provide: ADMIN_SEEDER, useClass: IdentityAdminSeeder },
  ],
  exports: [IDENTITY_SERVICE],
})
export class IdentityModule {}
