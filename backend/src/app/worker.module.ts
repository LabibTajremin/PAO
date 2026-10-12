import {
  type DynamicModule,
  Inject,
  Injectable,
  Module,
  type OnApplicationBootstrap,
  type OnApplicationShutdown,
} from '@nestjs/common';
import { ModulesContainer } from '@nestjs/core';
import { CLOCK, type Clock } from '../platform/clock/clock';
import { type AppConfig } from '../platform/config/app-config';
import { DATABASE, type Database } from '../platform/db/database';
import { readModuleLists } from '../platform/db/migration-files';
import { EventBus } from '../platform/events/event-bus';
import { JobScheduler } from '../platform/jobs/scheduler';
import { LOGGER, type Logger } from '../platform/logging/logger';
import { type Metrics, METRICS } from '../platform/metrics/metrics';
import {
  OUTBOX_RETENTION_MS,
  purgePublishedEvents,
  readOutboxBacklog,
} from '../platform/outbox/outbox';
import { OutboxRelay } from '../platform/outbox/outbox-relay';
import { findWorkerHooks } from '../platform/worker/worker-hooks';
import { BackendModule } from './backend.module';

const RELAY_INTERVAL_MS = 250;

/**
 * Runs what the worker exists for: every module's event subscribers behind the outbox
 * relay, and every module's periodic jobs plus the daily outbox purge.
 */
@Injectable()
export class WorkerRuntime implements OnApplicationBootstrap, OnApplicationShutdown {
  readonly bus = new EventBus();
  readonly scheduler: JobScheduler;
  readonly relay: OutboxRelay;
  @Inject(ModulesContainer) private readonly modules!: ModulesContainer;

  constructor(
    @Inject(DATABASE) db: Database,
    @Inject(CLOCK) clock: Clock,
    @Inject(LOGGER) log: Logger,
    @Inject(METRICS) metrics: Metrics,
  ) {
    const observer = metrics.worker;
    this.scheduler = new JobScheduler(db, clock, log, observer);
    const outboxModules = readModuleLists().outboxModules;
    this.relay = new OutboxRelay(db, this.bus, outboxModules, { clock, log, observer });
    observer.trackBacklog(() => readOutboxBacklog(db, outboxModules, clock.now()));
    this.scheduler.dailyAt(3, 0, 'outbox.purge_published', () =>
      purgePublishedEvents(
        db,
        outboxModules,
        new Date(clock.now().getTime() - OUTBOX_RETENTION_MS),
      ),
    );
  }

  onApplicationBootstrap(): void {
    for (const hooks of findWorkerHooks(this.modules)) {
      hooks.subscribe?.(this.bus);
      hooks.schedule?.(this.scheduler);
    }
    this.relay.start(RELAY_INTERVAL_MS);
    this.scheduler.start();
  }

  async onApplicationShutdown(): Promise<void> {
    await Promise.all([this.relay.stop(), this.scheduler.stop()]);
  }
}

/** The worker composition root. */
@Module({})
export class WorkerModule {
  static forRoot(config?: AppConfig): DynamicModule {
    return {
      module: WorkerModule,
      imports: [BackendModule.forRoot(config)],
      providers: [WorkerRuntime],
    };
  }
}
