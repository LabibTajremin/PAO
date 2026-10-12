import { type ModuleRef } from '@nestjs/core';
import { MEDIA_SERVICE } from '../../../media/contract/media-service';
import { DomainError } from '../../../../platform/errors/domain-error';
import { MediaErrors } from '../../../media/contract/errors';
import { MediaFiles } from './files';
import { MediaDocuments } from './peers';

describe('verification peers', () => {
  it('passes media failures other than an unknown upload on', async () => {
    const down = new Error('media down');
    const media = { getObject: () => Promise.reject(down) };
    const ref = { get: (t: symbol) => (t === MEDIA_SERVICE ? media : undefined) };
    const docs = new MediaDocuments(ref as unknown as ModuleRef);
    await expect(docs.attach('owner', 'm', ['selfie'])).rejects.toBe(down);
  });

  it('ignores an already deleted file but passes other media failures on', async () => {
    const gone = new DomainError(MediaErrors.NotFound);
    const down = new Error('media down');
    const failures: Error[] = [gone, down];
    const media = { delete: () => Promise.reject(failures.shift() ?? down) };
    const ref = { get: (t: symbol) => (t === MEDIA_SERVICE ? media : undefined) };
    const files = new MediaFiles(ref as unknown as ModuleRef);
    await expect(files.delete('m')).resolves.toBeUndefined();
    await expect(files.delete('m')).rejects.toBe(down);
  });
});
