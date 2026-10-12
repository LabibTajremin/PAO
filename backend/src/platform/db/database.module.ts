import { Global, Inject, Module, type OnApplicationShutdown } from '@nestjs/common';
import { APP_CONFIG, type AppConfig } from '../config/app-config';
import { connectDatabase, DATABASE, type Database } from './database';

/** Opens the Postgres pool at start-up (failing fast) and closes it on shutdown. */
@Global()
@Module({
  providers: [
    {
      provide: DATABASE,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => connectDatabase(config.databaseUrl),
    },
  ],
  exports: [DATABASE],
})
export class DatabaseModule implements OnApplicationShutdown {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  async onApplicationShutdown(): Promise<void> {
    await this.db.close();
  }
}
