/**
 * The container health check: resolves only when `url` answers 200 within `timeoutMs`.
 * The image runs `/app/api healthcheck` instead of shipping curl.
 */
export async function probe(url: string, timeoutMs: number): Promise<void> {
  let res: Response;
  try {
    res = await fetch(url, { signal: AbortSignal.timeout(timeoutMs) });
  } catch (cause) {
    throw new Error(`probe ${url}`, { cause });
  }
  await res.body?.cancel();
  if (res.status !== 200) {
    throw new Error(`probe ${url}: status ${res.status}`);
  }
}
