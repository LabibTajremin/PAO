import { AsyncLocalStorage } from 'node:async_hooks';

/** Fields that belong to one request and appear on every log line written while serving it. */
export interface RequestContext {
  requestId: string;
  userId?: string;
}

const storage = new AsyncLocalStorage<RequestContext>();

/** Runs `fn` with `ctx` as the current request context. */
export function runWithRequestContext<T>(ctx: RequestContext, fn: () => T): T {
  return storage.run(ctx, fn);
}

/** Returns the current request context, if code runs on behalf of a request. */
export function currentRequestContext(): RequestContext | undefined {
  return storage.getStore();
}

/** Records the authenticated account on the current request context for logging. */
export function setRequestUserId(userId: string): void {
  const ctx = storage.getStore();
  if (ctx) {
    ctx.userId = userId;
  }
}
