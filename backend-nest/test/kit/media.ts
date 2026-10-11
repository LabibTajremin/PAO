// Media helpers (the Go testkit API.Upload).
import { ConfirmUpload } from '../../src/modules/media/app/confirm-upload';
import { CreateUpload } from '../../src/modules/media/app/create-upload';
import { type Uploader } from '../../src/modules/media/domain/media';
import { type TestApi } from './api';

/** PUTs `body` to a presigned upload URL with its headers; returns the HTTP status. */
export async function putFile(
  ticket: { url: string; headers: Readonly<Record<string, string>> },
  body: Uint8Array,
): Promise<number> {
  const res = await fetch(ticket.url, { method: 'PUT', headers: ticket.headers, body });
  await res.arrayBuffer();
  return res.status;
}

/**
 * Stores a small confirmed JPEG for `ownerId` with `purpose` and returns its media id,
 * going through the presigned URL like an app would.
 */
export async function upload(
  api: TestApi,
  ownerId: string,
  uploader: Uploader,
  purpose: string,
): Promise<string> {
  const body = new TextEncoder().encode('file');
  const uploads = api.app.get(CreateUpload, { strict: false });
  const ticket = await uploads.create(ownerId, uploader, {
    purpose,
    contentType: 'image/jpeg',
    sizeBytes: body.length,
  });
  const status = await putFile(ticket, body);
  if (status !== 200) {
    throw new Error(`put ${purpose}: ${String(status)}`);
  }
  await api.app.get(ConfirmUpload, { strict: false }).confirm(ownerId, ticket.mediaId);
  return ticket.mediaId;
}
