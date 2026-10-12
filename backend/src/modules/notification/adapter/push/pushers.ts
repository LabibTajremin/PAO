import { readFile } from 'node:fs/promises';
import { type Provider } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../../../../platform/config/app-config';
import { LOGGER, type Logger } from '../../../../platform/logging/logger';
import { PUSH_CAPTURE } from '../../../../platform/testing/test-hooks';
import { PUSHER, type Pusher } from '../../port/ports';
import { CapturePusher } from './capture';
import { fcmFromCredentials } from './fcm';

/** Builds the pusher PUSH_ADAPTER names: FCM, or the capture used everywhere else. */
export async function pusherFor(config: AppConfig, log: Logger): Promise<Pusher> {
  if (config.pushAdapter === 'fcm') {
    return fcmFromCredentials(await readFile(config.fcmCredentialsFile, 'utf8'));
  }
  return new CapturePusher(log);
}

/** The pusher, and the capture the `/__test/pushes` hook reads unless FCM is used. */
export const pushProviders: Provider[] = [
  { provide: PUSHER, inject: [APP_CONFIG, LOGGER], useFactory: pusherFor },
  {
    provide: PUSH_CAPTURE,
    inject: [PUSHER],
    useFactory: (p: Pusher) => (p instanceof CapturePusher ? p : undefined),
  },
];
