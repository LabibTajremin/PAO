import {
  CreateBucketCommand,
  DeleteObjectCommand,
  GetObjectCommand,
  HeadBucketCommand,
  HeadObjectCommand,
  PutBucketEncryptionCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { type S3Config } from '../config/app-config';

/** Thrown when an object does not exist. */
export class ObjectNotFoundError extends Error {
  constructor(bucket: string, key: string) {
    super(`object not found: ${bucket}/${key}`);
    this.name = 'ObjectNotFoundError';
  }
}

/** An object's stored metadata. */
export interface ObjectInfo {
  readonly size: number;
  readonly contentType: string;
}

/** A presigned upload: the URL and the headers the client must send with the PUT. */
export interface PresignedUpload {
  readonly url: string;
  readonly headers: Readonly<Record<string, string>>;
}

function isNotFound(err: unknown): boolean {
  return (err as { $metadata?: { httpStatusCode?: number } }).$metadata?.httpStatusCode === 404;
}

async function attempt<T>(what: string, fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (cause) {
    throw new Error(what, { cause });
  }
}

/**
 * S3-compatible object storage: presigned uploads and downloads, metadata checks and
 * deletes (PRD §6.6). Buckets are private; clients only get short-lived signed URLs,
 * signed for the endpoint devices reach.
 */
export class ObjectStore {
  private readonly client: S3Client;
  private readonly presigner: S3Client;
  private readonly anonymous: boolean;

  constructor(
    cfg: Pick<S3Config, 'endpoint' | 'publicEndpoint' | 'region' | 'accessKey' | 'secretKey'>,
  ) {
    const build = (endpoint: string): S3Client =>
      new S3Client({
        endpoint,
        region: cfg.region,
        credentials: { accessKeyId: cfg.accessKey, secretAccessKey: cfg.secretKey },
        forcePathStyle: true,
        // Presigned uploads come from phones that cannot add SDK checksum headers.
        requestChecksumCalculation: 'WHEN_REQUIRED',
        responseChecksumValidation: 'WHEN_REQUIRED',
      });
    this.client = build(cfg.endpoint);
    this.presigner = build(cfg.publicEndpoint);
    this.anonymous = cfg.accessKey === '' || cfg.secretKey === '';
  }

  /** A URL accepting one PUT of exactly `size` bytes of `contentType`; storage rejects anything else. */
  presignPut(req: {
    bucket: string;
    key: string;
    contentType: string;
    size: number;
    ttlSeconds: number;
  }): Promise<PresignedUpload> {
    return attempt(`presign put ${req.bucket}/${req.key}`, async () => {
      this.requireCredentials();
      const command = new PutObjectCommand({
        Bucket: req.bucket,
        Key: req.key,
        ContentType: req.contentType,
        ContentLength: req.size,
      });
      const url = await getSignedUrl(this.presigner, command, {
        expiresIn: req.ttlSeconds,
        signableHeaders: new Set(['content-type', 'content-length']),
      });
      return { url, headers: { 'Content-Type': req.contentType } };
    });
  }

  /** A URL that downloads the object until `ttlSeconds` pass (5 minutes for documents). */
  presignGet(bucket: string, key: string, ttlSeconds: number): Promise<string> {
    return attempt(`presign get ${bucket}/${key}`, () => {
      this.requireCredentials();
      return getSignedUrl(this.presigner, new GetObjectCommand({ Bucket: bucket, Key: key }), {
        expiresIn: ttlSeconds,
      });
    });
  }

  // A URL signed without credentials would only ever be refused by storage.
  private requireCredentials(): void {
    if (this.anonymous) {
      throw new Error('no storage credentials to sign with');
    }
  }

  /** Returns the object's metadata or throws {@link ObjectNotFoundError}. */
  async head(bucket: string, key: string): Promise<ObjectInfo> {
    try {
      const out = await this.client.send(new HeadObjectCommand({ Bucket: bucket, Key: key }));
      return { size: out.ContentLength ?? 0, contentType: out.ContentType ?? '' };
    } catch (err) {
      throw isNotFound(err)
        ? new ObjectNotFoundError(bucket, key)
        : new Error(`head ${bucket}/${key}`, { cause: err });
    }
  }

  /** Removes an object; deleting a missing object succeeds. */
  async delete(bucket: string, key: string): Promise<void> {
    await attempt(`delete ${bucket}/${key}`, () =>
      this.client.send(new DeleteObjectCommand({ Bucket: bucket, Key: key })),
    );
  }

  /**
   * Creates the bucket when missing and asks for default AES-256 server-side encryption,
   * so documents are encrypted at rest (PRD §6.6).
   */
  async ensureBucket(bucket: string): Promise<void> {
    await attempt(`ensure bucket ${bucket}`, async () => {
      try {
        await this.client.send(new HeadBucketCommand({ Bucket: bucket }));
      } catch (err) {
        if (!isNotFound(err)) {
          throw err;
        }
        await this.client.send(new CreateBucketCommand({ Bucket: bucket }));
      }
      await this.client.send(
        new PutBucketEncryptionCommand({
          Bucket: bucket,
          ServerSideEncryptionConfiguration: {
            Rules: [{ ApplyServerSideEncryptionByDefault: { SSEAlgorithm: 'AES256' } }],
          },
        }),
      );
    });
  }

  /** Checks that storage answers, for readiness. */
  async ping(bucket: string): Promise<void> {
    await attempt('storage ping', () =>
      this.client.send(new HeadBucketCommand({ Bucket: bucket })),
    );
  }

  /** Closes the HTTP connections. */
  close(): void {
    this.client.destroy();
    this.presigner.destroy();
  }
}
