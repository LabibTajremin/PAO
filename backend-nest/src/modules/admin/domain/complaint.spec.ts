import {
  assign,
  type Complaint,
  type ComplaintReport,
  isValidReport,
  isValidResolution,
  resolve,
  ticketNumber,
} from './complaint';

const photo = '0192f5a0-0000-7000-8000-000000000001';
const ok: ComplaintReport = {
  bookingId: 'b',
  reporterId: 'r',
  reporterRole: 'customer',
  reason: 'late',
  description: 'Arrived two hours late.',
  photos: [photo],
};

describe('complaint', () => {
  it('accepts a complete report', () => {
    expect(isValidReport(ok)).toBe(true);
  });

  it.each<[string, Partial<ComplaintReport>]>([
    ['reason', { reason: 'rude' }],
    ['short', { description: '  late    ' }],
    ['long', { description: 'x'.repeat(1001) }],
    ['many photos', { photos: ['1', '2', '3', '4', '5', '6'] }],
    ['duplicate', { photos: [photo, photo] }],
  ])('refuses a report with a bad %s', (_name, change) => {
    expect(isValidReport({ ...ok, ...change })).toBe(false);
  });

  it('checks the resolution note length in characters', () => {
    expect(isValidResolution('  ok   ')).toBe(false);
    expect(isValidResolution('অনেক ভাল')).toBe(true);
    expect(isValidResolution('x'.repeat(1001))).toBe(false);
  });

  it('assigns, reassigns and resolves', () => {
    const now = new Date('2026-10-09T10:00:00Z');
    const open = { status: 'open', ticket: 42 } as Complaint;
    expect(ticketNumber(open)).toBe('TCK-000042');
    const assigned = assign(open, 'agent', now);
    expect(assigned).toMatchObject({ status: 'assigned', assigneeId: 'agent', updatedAt: now });
    expect(assign(assigned, 'other', now).assigneeId).toBe('other');
    const done = resolve(assigned, 'Refund issued to the customer.', true, now);
    expect(done).toMatchObject({ status: 'resolved', verified: true, resolvedAt: now });
  });
});
