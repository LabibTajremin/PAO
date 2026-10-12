import { boom, providerFixture } from '../../../../test/fakes/provider';
import { DomainError } from '../../../platform/errors/domain-error';
import { ProviderEvents } from '../contract/events';
import { ProviderReasons } from '../domain/reasons';

const ID = '0192a000-0000-7000-8000-0000000000aa';
const dhaka = { lat: 23.79, lng: 90.41 };
const reason = (r: string) => ({ reason: r });

function personal(now: Date) {
  const dob = new Date(now);
  dob.setUTCFullYear(dob.getUTCFullYear() - 30);
  return {
    fullName: ' Rahim Uddin ',
    dateOfBirth: dob,
    gender: 'male',
    presentAddress: 'Banani 11',
    permanentAddress: 'Cumilla Sadar',
    bio: '',
  };
}

describe('enrolment', () => {
  it('saves every step, then submits', async () => {
    const f = providerFixture();
    const fresh = await f.enrolment.progress(ID);
    expect(fresh.complete).toBe(false);
    expect(fresh.steps).toHaveLength(9);
    await f.enrolment.savePersonal(ID, personal(f.clock.now()));
    await f.enrolment.saveServices(ID, [f.electric], 8);
    await f.enrolment.saveArea(ID, dhaka, 8000);
    const contact = { name: 'Karim', relation: 'Brother', phone: '01812345678' };
    await f.contact.save(ID, contact);
    expect(f.peers.sent).toEqual(['+8801812345678']);
    await f.contact.verify(ID, '123456');
    await f.enrolment.acceptCodeOfConduct(ID, '2026-10', true);
    await expect(f.enrolment.markSubmitted(ID)).rejects.toMatchObject(
      reason(ProviderReasons.EnrolmentIncomplete),
    );
    for (const s of ['nid', 'selfie', 'police_clearance']) {
      await f.enrolment.markStepDone(ID, s);
    }
    await f.enrolment.markSubmitted(ID);
    expect(await f.enrolment.progress(ID)).toMatchObject({ complete: true, submitted: true });
    const saved = f.repo.events.filter((e) => e.name === ProviderEvents.EnrolmentStepSaved);
    const row = f.repo.rows.get(ID);
    expect(saved).toHaveLength(5);
    expect(row?.fullName).toBe('Rahim Uddin');
    expect(row?.emergency.verifiedAt).not.toBeNull();
    expect(row?.cocAcceptedAt).not.toBeNull();
    await f.contact.save(ID, { ...contact, phone: '01912345678' });
    expect((await f.enrolment.progress(ID)).complete).toBe(false);
    f.peers.codeErr = new DomainError(ProviderReasons.CodeRejected);
    await expect(f.contact.verify(ID, '000000')).rejects.toMatchObject(
      reason(ProviderReasons.CodeRejected),
    );
  });

  it('rejects bad steps', async () => {
    const f = providerFixture();
    const young = { ...personal(f.clock.now()), dateOfBirth: new Date('2009-10-09T00:00:00Z') };
    await expect(f.enrolment.savePersonal(ID, young)).rejects.toMatchObject(
      reason(ProviderReasons.TooYoung),
    );
    await expect(f.enrolment.saveServices(ID, [], 1)).rejects.toMatchObject(
      reason(ProviderReasons.Invalid),
    );
    await expect(f.enrolment.saveServices(ID, ['unknown'], 1)).rejects.toMatchObject(
      reason(ProviderReasons.UnknownService),
    );
    const hidden = { id: 'hidden', name: { en: '', bn: '' }, published: false, minLevel: 1 };
    f.peers.services.set('hidden', { ...hidden, womenProvidersOnly: false });
    await expect(f.enrolment.saveServices(ID, ['hidden'], 1)).rejects.toMatchObject(
      reason(ProviderReasons.UnknownService),
    );
    await expect(f.enrolment.saveArea(ID, dhaka, 10)).rejects.toMatchObject(
      reason(ProviderReasons.Invalid),
    );
    const bad = { name: 'K', relation: 'Brother', phone: 'x' };
    await expect(f.contact.save(ID, bad)).rejects.toMatchObject(reason(ProviderReasons.Invalid));
    const self = { name: 'Karim', relation: 'Self', phone: '01712345678' };
    await expect(f.contact.save(ID, self)).rejects.toMatchObject(reason(ProviderReasons.Invalid));
    await expect(f.contact.verify(ID, '1')).rejects.toMatchObject(
      reason(ProviderReasons.ContactUnproven),
    );
    await expect(f.enrolment.acceptCodeOfConduct(ID, '2026-10', false)).rejects.toMatchObject(
      reason(ProviderReasons.Invalid),
    );
    f.peers.codeErr = boom;
    const other = { name: 'Karim', relation: 'Brother', phone: '01812345678' };
    await expect(f.contact.save(ID, other)).rejects.toBe(boom);
    // A failed send must not save the contact.
    await expect(f.contact.verify(ID, '1')).rejects.toMatchObject(
      reason(ProviderReasons.ContactUnproven),
    );
  });

  it('passes store failures on', async () => {
    const f = providerFixture();
    f.repo.getErr = boom;
    await expect(f.enrolment.progress(ID)).rejects.toBe(boom);
    await expect(f.enrolment.markSubmitted(ID)).rejects.toBe(boom);
    f.repo.getErr = undefined;
    f.peers.err = boom;
    await expect(f.enrolment.markStepDone(ID, 'nid')).rejects.toBe(boom);
    f.peers.err = undefined;
    f.repo.err = boom;
    await expect(f.enrolment.markStepDone(ID, 'nid')).rejects.toBe(boom);
    f.repo.err = undefined;
    await f.enrolment.markStepDone(ID, 'nid');
    f.repo.err = boom;
    await expect(f.enrolment.markStepDone(ID, 'selfie')).rejects.toBe(boom);
    f.repo.err = undefined;
    f.presence.err = boom;
    await expect(f.enrolment.saveServices(ID, [f.electric], 1)).rejects.toBe(boom);
  });

  it('accepts an 18th birthday in Dhaka after 18:00 UTC', async () => {
    const f = providerFixture();
    f.clock.set(new Date('2026-10-11T20:00:00Z'));
    const adult = { ...personal(f.clock.now()), dateOfBirth: new Date('2008-10-12T00:00:00Z') };
    await expect(f.enrolment.savePersonal(ID, adult)).resolves.toMatchObject({ complete: false });
  });
});
