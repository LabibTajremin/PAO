import { type ModuleRef } from '@nestjs/core';
import { MEDIA_SERVICE } from '../../../media/contract/media-service';
import { MediaDocuments } from './peers';

describe('verification peers', () => {
  it('passes media failures other than an unknown upload on', async () => {
    const down = new Error('media down');
    const media = { getObject: () => Promise.reject(down) };
    const ref = { get: (t: symbol) => (t === MEDIA_SERVICE ? media : undefined) };
    const docs = new MediaDocuments(ref as unknown as ModuleRef);
    await expect(docs.attach('owner', 'm', ['selfie'])).rejects.toBe(down);
  });
});
