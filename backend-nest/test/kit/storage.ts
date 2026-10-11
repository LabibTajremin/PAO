// Private buckets for specs on the shared S3 service; each is emptied and removed after.
import { randomUUID } from 'node:crypto';
import {
  DeleteBucketCommand,
  DeleteObjectsCommand,
  ListObjectsV2Command,
  S3Client,
} from '@aws-sdk/client-s3';
import { type S3Config } from '../../src/platform/config/app-config';
import { ObjectStore } from '../../src/platform/storage/object-store';
import { onCleanup, testEnv } from './cleanup';

/** S3 settings for the test storage service, with two fresh bucket names. */
export function testS3Config(): S3Config {
  const endpoint = testEnv('PAO_TEST_S3_ENDPOINT');
  return {
    endpoint,
    publicEndpoint: endpoint,
    region: 'us-east-1',
    accessKey: testEnv('PAO_TEST_S3_ACCESS_KEY'),
    secretKey: testEnv('PAO_TEST_S3_SECRET_KEY'),
    bucketPrivate: bucketName(),
    bucketPublic: bucketName(),
  };
}

function bucketName(): string {
  const name = 't-' + randomUUID().replaceAll('-', '').slice(0, 20);
  onCleanup(() => removeBucket(name));
  return name;
}

async function removeBucket(bucket: string): Promise<void> {
  const cfg = { endpoint: testEnv('PAO_TEST_S3_ENDPOINT') };
  const s3 = new S3Client({
    endpoint: cfg.endpoint,
    region: 'us-east-1',
    forcePathStyle: true,
    credentials: {
      accessKeyId: testEnv('PAO_TEST_S3_ACCESS_KEY'),
      secretAccessKey: testEnv('PAO_TEST_S3_SECRET_KEY'),
    },
  });
  try {
    const listed = await s3.send(new ListObjectsV2Command({ Bucket: bucket }));
    const objects = (listed.Contents ?? []).map((o) => ({ Key: o.Key }));
    if (objects.length > 0) {
      await s3.send(new DeleteObjectsCommand({ Bucket: bucket, Delete: { Objects: objects } }));
    }
    await s3.send(new DeleteBucketCommand({ Bucket: bucket }));
  } finally {
    s3.destroy();
  }
}

/** A store on the test service and a private bucket that already exists. */
export async function testBucket(): Promise<{ store: ObjectStore; bucket: string }> {
  const cfg = testS3Config();
  const store = new ObjectStore(cfg);
  onCleanup(() => {
    store.close();
    return Promise.resolve();
  });
  await store.ensureBucket(cfg.bucketPrivate);
  return { store, bucket: cfg.bucketPrivate };
}
