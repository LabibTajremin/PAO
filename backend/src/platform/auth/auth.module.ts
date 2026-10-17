import { Global, Module } from '@nestjs/common';
import { CLOCK, type Clock } from '../clock/clock';
import { APP_CONFIG, type AppConfig } from '../config/app-config';
import { ID_GENERATOR, type IdGenerator } from '../ids/id-generator';
import { TokenSigner, TokenVerifier } from './access-token';
import { DataCipher } from './data-cipher';
import { publicKeyOf } from './ed25519';

/** Access tokens live 15 minutes (02-architecture §5). */
export const ACCESS_TOKEN_TTL_MS = 15 * 60 * 1000;

/** Provides the token signer and verifier and the field cipher from the configuration. */
@Global()
@Module({
  providers: [
    {
      provide: TokenSigner,
      inject: [APP_CONFIG, CLOCK, ID_GENERATOR],
      useFactory: (config: AppConfig, clock: Clock, ids: IdGenerator) =>
        new TokenSigner(
          { keyId: config.jwt.keyId, key: config.jwt.signingKey, ttlMs: ACCESS_TOKEN_TTL_MS },
          clock,
          ids,
        ),
    },
    {
      provide: TokenVerifier,
      inject: [APP_CONFIG, CLOCK],
      useFactory: (config: AppConfig, clock: Clock) => {
        const keys = new Map(config.jwt.previousKeys);
        keys.set(config.jwt.keyId, publicKeyOf(config.jwt.signingKey));
        return new TokenVerifier(keys, clock);
      },
    },
    {
      provide: DataCipher,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => new DataCipher(config.dataEncryptionKey),
    },
  ],
  exports: [TokenSigner, TokenVerifier, DataCipher],
})
export class AuthModule {}
