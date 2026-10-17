import {
  approveAll,
  boom,
  enrolled,
  verificationFixture,
} from '../../../../test/fakes/verification';
import { DomainError } from '../../../platform/errors/domain-error';
import { VerificationEvents } from '../contract/events';
import { VerificationReasons } from '../domain/reasons';
import { itemOf } from '../domain/state';

const reason = (r: string) => ({ reason: r });

describe('verification flow', () => {
  it('submits, reviews and reaches Level 1', async () => {
    const f = verificationFixture();
    await enrolled(f);
    expect(f.peers.steps.get(f.id)).toHaveLength(4);
    const st = await f.status.submit(f.id);
    expect(st).toMatchObject({ level: 0, serviceIds: [expect.any(String)] });
    expect(st.submittedAt).not.toBeNull();
    const reject = { providerId: f.id, actor: 'v', approve: false };
    await expect(f.review.decide({ ...reject, item: 'nid', reason: 'x' })).rejects.toMatchObject(
      reason(VerificationReasons.Invalid),
    );
    await f.review.decide({ ...reject, item: 'selfie', reason: 'Blurred photo' });
    await f.documents.saveSelfie(f.id, 'again');
    await approveAll(f);
    expect(await f.states.level(f.id)).toBe(1);
    expect(await f.states.canReceiveBookings(f.id, null)).toBe(true);
    expect(await f.states.canReceiveBookings(f.id, 'svc')).toBe(true);
    expect((await f.states.levels([f.id])).get(f.id)).toBe(1);
    const review = await f.review.review(f.id);
    expect(review).toMatchObject({ nidNumber: '1234567890', provider: { fullName: 'Rahim' } });
    const count = (name: string) => f.repo.events.filter((e) => e.name === name).length;
    expect(count(VerificationEvents.DocumentApproved)).toBe(8);
    expect(count(VerificationEvents.DocumentRejected)).toBe(1);
    expect(count(VerificationEvents.ProviderLevelChanged)).toBe(1);
    expect((await f.states.items(f.id)).map((i) => i.type)[0]).toBe('address');
    expect(await f.states.countPendingReviews()).toBe(1);
    await f.changes.onStepSaved(f.id, 'personal');
    const after = await f.status.status(f.id);
    expect(after.level).toBe(0);
    expect([itemOf(after, 'nid').status, itemOf(after, 'address').status]).toEqual([
      'pending',
      'pending',
    ]);
    await f.changes.onStepSaved(f.id, 'selfie');
  });

  it('rejects bad documents and decisions', async () => {
    const f = verificationFixture();
    await expect(f.documents.saveNid(f.id, '12', 'a', 'b')).rejects.toMatchObject(
      reason(VerificationReasons.Invalid),
    );
    f.repo.blocked.add('h:9999999999');
    await expect(f.documents.saveNid(f.id, '9999999999', 'a', 'b')).rejects.toMatchObject(
      reason(VerificationReasons.NidBlocked),
    );
    const old = new Date('2024-10-09T00:00:00Z');
    await expect(f.documents.savePoliceClearance(f.id, 'c', old)).rejects.toMatchObject(
      reason(VerificationReasons.ClearanceTooOld),
    );
    await expect(f.documents.saveSkillProof(f.id, [])).rejects.toMatchObject(
      reason(VerificationReasons.Invalid),
    );
    f.peers.mediaErr = new DomainError(VerificationReasons.BadDocument);
    await expect(f.documents.saveSelfie(f.id, 's')).rejects.toBe(f.peers.mediaErr);
    f.peers.mediaErr = undefined;
    f.peers.submitErr = new DomainError(VerificationReasons.EnrolmentPending);
    await expect(f.status.submit(f.id)).rejects.toBe(f.peers.submitErr);
    const approve = { providerId: f.id, item: 'nid', actor: 'v', approve: true, reason: '' };
    await expect(f.review.decide(approve)).rejects.toMatchObject(
      reason(VerificationReasons.NotPending),
    );
    await expect(f.review.review('nobody')).rejects.toMatchObject(
      reason(VerificationReasons.NotFound),
    );
    await expect(f.changes.onStepSaved('nobody', 'area')).rejects.toMatchObject(
      reason(VerificationReasons.NotFound),
    );
  });

  it('passes store failures on', async () => {
    const f = verificationFixture();
    await enrolled(f);
    f.cipher.broken = true;
    await expect(f.review.review(f.id)).rejects.toBe(boom);
    f.repo.err = boom;
    const calls = [
      () => f.documents.saveNid(f.id, '1234567890', 'a', 'b'),
      () => f.documents.saveSelfie(f.id, 's'),
      () => f.status.status(f.id),
      () => f.status.submit(f.id),
      () =>
        f.review.decide({ providerId: f.id, item: 'nid', actor: 'v', approve: true, reason: '' }),
      () => f.states.canReceiveBookings(f.id, null),
      () => f.changes.onAccountStatus(f.id, 'banned'),
    ];
    for (const call of calls) {
      await expect(call()).rejects.toBe(boom);
    }
    f.repo.err = undefined;
    f.peers.err = boom;
    await expect(f.documents.savePoliceClearance(f.id, 'c', f.clock.now())).rejects.toBe(boom);
    const page = { at: null, id: null, limit: 21 };
    const filter = { itemType: null, serviceId: null };
    expect(await f.review.queue(filter, page)).toEqual([]);
    const submittedAt = new Date(f.clock.now().getTime() - 5 * 60 * 60 * 1000);
    f.repo.queueRows = [{ providerId: f.id, submittedAt, pendingItems: [], serviceIds: ['svc'] }];
    await expect(f.review.queue(filter, page)).rejects.toBe(boom);
    f.peers.err = undefined;
    const rows = await f.review.queue(filter, page);
    expect(rows[0]).toMatchObject({ ageHours: 5, name: 'Rahim' });
    expect(rows[0]?.services).toHaveLength(1);
  });

  it('accepts a clearance issued today in Dhaka after 18:00 UTC', async () => {
    const f = verificationFixture();
    f.clock.set(new Date('2026-10-11T20:00:00Z'));
    const issued = new Date('2026-10-12T00:00:00Z');
    await expect(f.documents.savePoliceClearance(f.id, 'c', issued)).resolves.toBeDefined();
  });
});
