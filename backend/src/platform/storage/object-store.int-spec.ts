import { Test } from '@nestjs/testing';
import { testBucket, testS3Config } from '../../../test/kit/storage';
import { type AppConfig } from '../config/app-config';
import { ConfigModule } from '../config/config.module';
import { ObjectNotFoundError, ObjectStore } from './object-store';
import { StorageModule } from './storage.module';

const MINUTES_5 = 300;

describe('ObjectStore', () => {
  it('uploads through a presigned URL, views, inspects and deletes', async () => {
    const { store, bucket } = await testBucket();
    await store.ensureBucket(bucket);
    const body = Buffer.from('fake-jpeg-bytes');
    const upload = await store.presignPut({
      bucket,
      key: 'docs/a.jpg',
      contentType: 'image/jpeg',
      size: body.length,
      ttlSeconds: MINUTES_5,
    });
    expect(upload.headers).toEqual({ 'Content-Type': 'image/jpeg' });
    const put = await fetch(upload.url, { method: 'PUT', headers: upload.headers, body });
    expect(put.status).toBe(200);
    expect(await store.head(bucket, 'docs/a.jpg')).toEqual({
      size: body.length,
      contentType: 'image/jpeg',
    });
    const view = await fetch(await store.presignGet(bucket, 'docs/a.jpg', MINUTES_5));
    expect(view.status).toBe(200);
    expect(Buffer.from(await view.arrayBuffer()).toString()).toBe('fake-jpeg-bytes');
    await store.delete(bucket, 'docs/a.jpg');
    await expect(store.head(bucket, 'docs/a.jpg')).rejects.toBeInstanceOf(ObjectNotFoundError);
    await store.delete(bucket, 'docs/a.jpg');
    await expect(store.ping(bucket)).resolves.toBeUndefined();
  });

  it('refuses an upload of another type than signed', async () => {
    const { store, bucket } = await testBucket();
    const upload = await store.presignPut({
      bucket,
      key: 'docs/b.jpg',
      contentType: 'image/jpeg',
      size: 3,
      ttlSeconds: MINUTES_5,
    });
    const put = await fetch(upload.url, {
      method: 'PUT',
      headers: { 'Content-Type': 'text/html' },
      body: 'abc',
    });
    expect(put.status).toBe(403);
  });

  it('reports failures with bad credentials', async () => {
    const bad = new ObjectStore({ ...testS3Config(), secretKey: 'wrong' });
    await expect(bad.ensureBucket('t-nope')).rejects.toThrow('ensure bucket t-nope');
    await expect(bad.head('t-nope', 'k')).rejects.toThrow('head t-nope/k');
    await expect(bad.delete('t-nope', 'k')).rejects.toThrow('delete t-nope/k');
    await expect(bad.ping('t-nope')).rejects.toThrow('storage ping');
    bad.close();
    const anonymous = new ObjectStore({ ...testS3Config(), accessKey: '', secretKey: '' });
    const req = { bucket: 'b', key: 'k', contentType: 'image/jpeg', size: 1, ttlSeconds: 60 };
    await expect(anonymous.presignPut(req)).rejects.toThrow('presign put b/k');
    await expect(anonymous.presignGet('b', 'k', 60)).rejects.toThrow('presign get b/k');
    anonymous.close();
  });
});

describe('StorageModule', () => {
  it('prepares both buckets and refuses to start without storage', async () => {
    const s3 = testS3Config();
    const ref = await Test.createTestingModule({
      imports: [ConfigModule.forRoot({ s3 } as AppConfig), StorageModule],
    }).compile();
    const app = await ref.createNestApplication().init();
    const store = app.get(ObjectStore);
    await expect(store.ping(s3.bucketPublic)).resolves.toBeUndefined();
    await app.close();

    const broken = Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ s3: { ...s3, secretKey: 'wrong' } } as AppConfig),
        StorageModule,
      ],
    }).compile();
    await expect(broken).rejects.toThrow('prepare storage');
  });
});
