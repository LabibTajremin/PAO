// In-memory stand-ins for the media ports and the audit contract, for specs (the Go
// memRepo, memStore and memAudit).
import { FakeClock } from '../../../platform/clock/fake-clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { UuidV7Generator } from '../../../platform/ids/id-generator';
import { type ObjectInfo, ObjectNotFoundError } from '../../../platform/storage/object-store';
import { type AuditEntry, type AuditService } from '../../audit/contract';
import { type MediaObject, MediaReason } from '../domain/media';
import { type FileStore, type MediaRepository } from '../port/media-ports';
import { ConfirmUpload } from './confirm-upload';
import { CreateUpload } from './create-upload';
import { DocumentViewAudit } from './document-view-audit';
import { MediaObjects } from './media-objects';
import { ViewMedia } from './view-media';

/** Object records in a map; `faults` makes a method throw. */
class FakeMediaRepository implements MediaRepository {
  readonly objects = new Map<string, MediaObject>();
  readonly faults = new Map<keyof MediaRepository, Error>();

  private settle(method: keyof MediaRepository): Promise<void> {
    const err = this.faults.get(method);
    return err ? Promise.reject(err) : Promise.resolve();
  }

  private change(id: string, fields: Partial<MediaObject>): void {
    const o = this.objects.get(id);
    if (o) {
      this.objects.set(id, { ...o, ...fields });
    }
  }

  create(o: MediaObject): Promise<void> {
    this.objects.set(o.id, o);
    return this.settle('create');
  }

  async get(id: string): Promise<MediaObject> {
    const o = this.objects.get(id);
    if (!o) {
      throw new DomainError(MediaReason.NotFound);
    }
    await this.settle('get');
    return o;
  }

  markConfirmed(id: string): Promise<void> {
    this.change(id, { confirmed: true });
    return this.settle('markConfirmed');
  }

  markAttached(id: string): Promise<void> {
    this.change(id, { attached: true });
    return this.settle('markAttached');
  }

  delete(id: string): Promise<void> {
    this.objects.delete(id);
    return this.settle('delete');
  }

  async orphans(createdBefore: Date): Promise<MediaObject[]> {
    await this.settle('orphans');
    return [...this.objects.values()].filter((o) => !o.attached && o.createdAt < createdBefore);
  }
}

/** Stored files in a map; `faults` makes a method throw. */
class FakeFileStore implements FileStore {
  readonly uploadBucket = 'private';
  readonly files = new Map<string, ObjectInfo>();
  readonly faults = new Map<'presignPut' | 'presignGet' | 'head' | 'delete', Error>();

  private settle<T>(method: 'presignPut' | 'presignGet' | 'head' | 'delete', v: T): Promise<T> {
    const err = this.faults.get(method);
    return err ? Promise.reject(err) : Promise.resolve(v);
  }

  presignPut(req: { key: string; contentType: string }) {
    return this.settle('presignPut', {
      url: `put://${req.key}`,
      headers: { 'Content-Type': req.contentType },
    });
  }

  presignGet(_bucket: string, key: string): Promise<string> {
    return this.settle('presignGet', `get://${key}`);
  }

  async head(bucket: string, key: string): Promise<ObjectInfo> {
    const info = await this.settle('head', this.files.get(key));
    if (!info) {
      throw new ObjectNotFoundError(bucket, key);
    }
    return info;
  }

  delete(_bucket: string, key: string): Promise<void> {
    this.files.delete(key);
    return this.settle('delete', undefined);
  }
}

/** Keeps recorded entries; `failure` makes recording throw. */
class FakeAudit implements AuditService {
  readonly entries: AuditEntry[] = [];
  failure: Error | undefined;

  record(entry: AuditEntry): Promise<void> {
    this.entries.push(entry);
    return this.failure ? Promise.reject(this.failure) : Promise.resolve();
  }

  listForSubject(): Promise<AuditEntry[]> {
    return Promise.resolve(this.entries);
  }
}

/** Every media use case over fakes. */
export function fakeMedia() {
  const repo = new FakeMediaRepository();
  const store = new FakeFileStore();
  const audit = new FakeAudit();
  const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
  const ids = new UuidV7Generator();
  const viewAudit = new DocumentViewAudit(audit, clock, ids);
  return {
    repo,
    store,
    audit,
    clock,
    uploads: new CreateUpload(repo, store, clock, ids),
    confirmations: new ConfirmUpload(repo, store),
    views: new ViewMedia(repo, store, viewAudit, clock),
    objects: new MediaObjects(repo, store, clock),
  };
}

/** Uploads a 1000-byte JPEG for a provider and puts it in storage, as an app would. */
export async function uploaded(m: ReturnType<typeof fakeMedia>, ownerId: string, purpose: string) {
  const ticket = await m.uploads.create(ownerId, 'provider', {
    purpose,
    contentType: 'image/jpeg',
    sizeBytes: 1000,
  });
  const key = m.repo.objects.get(ticket.mediaId)?.key ?? '';
  m.store.files.set(key, { size: 1000, contentType: 'image/jpeg' });
  return ticket;
}
