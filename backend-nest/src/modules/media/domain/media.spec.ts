import { MediaReason, objectKey, ruleFor, type Uploader, uploadRefusal } from './media';

const MB = 1 << 20;

describe('upload rules', () => {
  it.each<[Uploader, string, string, number, string | undefined]>([
    ['provider', 'nid_front', 'image/jpeg', 1000, undefined],
    ['provider', 'police_clearance', 'application/pdf', 5 * MB, undefined],
    ['provider', 'selfie', 'application/pdf', 1000, MediaReason.Invalid],
    ['customer', 'avatar', 'image/png', 2 * MB + 1, MediaReason.Invalid],
    ['customer', 'avatar', 'image/png', 0, MediaReason.Invalid],
    ['customer', 'nid_front', 'image/png', 10, MediaReason.Forbidden],
    ['admin', 'level2_photo', 'image/png', 10, undefined],
    ['provider', 'level2_photo', 'image/png', 10, MediaReason.Forbidden],
    ['customer', 'toString', 'image/png', 10, MediaReason.Forbidden],
  ])('%s %s %s %d → %s', (...[uploader, purpose, contentType, sizeBytes, want]) => {
    expect(uploadRefusal(uploader, { purpose, contentType, sizeBytes })).toBe(want);
  });

  it('marks verification documents sensitive', () => {
    expect(ruleFor('nid_back')?.sensitive).toBe(true);
    expect(ruleFor('avatar')?.sensitive).toBe(false);
    expect(ruleFor('nope')).toBeUndefined();
  });

  it('places files by purpose and owner', () => {
    expect(objectKey('selfie', 'o', 'i')).toBe('selfie/o/i');
  });
});
