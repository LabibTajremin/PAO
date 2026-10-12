import { SetMetadata } from '@nestjs/common';
import { type ModulesContainer } from '@nestjs/core';
import { type EventBus } from '../events/event-bus';
import { type JobScheduler } from '../jobs/scheduler';

/**
 * What a module runs in the worker: its event subscribers and its periodic jobs. A
 * module provides one class implementing this, marked with {@link WorkerHooksProvider}.
 */
export interface WorkerHooks {
  subscribe?(bus: EventBus): void;
  schedule?(jobs: JobScheduler): void;
}

const WORKER_HOOKS = 'pao:worker-hooks';

/** Marks a provider whose {@link WorkerHooks} the worker (and the test kit) register. */
export const WorkerHooksProvider = (): ClassDecorator => SetMetadata(WORKER_HOOKS, true);

/** Returns every module's worker hooks among the app's modules. */
export function findWorkerHooks(modules: ModulesContainer): WorkerHooks[] {
  const hooks: WorkerHooks[] = [];
  for (const module of modules.values()) {
    for (const wrapper of module.providers.values()) {
      const type = wrapper.metatype as object | null;
      if (type && wrapper.instance && Reflect.getMetadata(WORKER_HOOKS, type) === true) {
        hooks.push(wrapper.instance);
      }
    }
  }
  return hooks;
}
