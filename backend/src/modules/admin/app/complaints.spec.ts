import { FakeClock } from '../../../platform/clock/fake-clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { SequenceIdGenerator } from '../../../platform/ids/id-generator';
import { type Comment, type Complaint, type ComplaintReport } from '../domain/complaint';
import { type ComplaintRepository, type NewComplaint } from '../port/complaint-repository';
import { type Admins, type Bookings, type EvidencePhotos } from '../port/peers';
import { AdminErrors } from './errors';
import { ReportProblem } from './report-problem';
import { WorkComplaints } from './work-complaints';

const now = new Date('2026-10-09T10:00:00Z');

class FakeRepo implements Partial<ComplaintRepository> {
  stored = new Map<string, Complaint>();
  events: DomainEvent[] = [];
  comments: Comment[] = [];

  createComplaint(c: NewComplaint, event: (s: Complaint) => DomainEvent): Promise<Complaint> {
    const stored = { ...c, ticket: 1001, comments: [] };
    this.stored.set(c.id, stored);
    this.events.push(event(stored));
    return Promise.resolve(stored);
  }

  getComplaint(id: string): Promise<Complaint> {
    const c = this.stored.get(id);
    if (!c) {
      return Promise.reject(new DomainError(AdminErrors.ComplaintNotFound));
    }
    return Promise.resolve({ ...c, comments: this.comments.filter((m) => m.complaintId === id) });
  }

  listComplaints(): Promise<Complaint[]> {
    return Promise.resolve([...this.stored.values()]);
  }

  async saveComplaint(
    id: string,
    change: (c: Complaint) => { complaint: Complaint; event?: DomainEvent },
  ): Promise<Complaint> {
    const { complaint, event } = change(await this.getComplaint(id));
    this.stored.set(id, complaint);
    if (event) {
      this.events.push(event);
    }
    return complaint;
  }

  addComment(c: Comment): Promise<void> {
    this.comments.push(c);
    return Promise.resolve();
  }
}

const bookings: Bookings = {
  parties: (id) =>
    id === 'b1'
      ? Promise.resolve({ customerId: 'cust', providerId: 'prov' })
      : Promise.reject(new DomainError(AdminErrors.BookingNotFound)),
};

const report: ComplaintReport = {
  bookingId: 'b1',
  reporterId: 'cust',
  reporterRole: 'customer',
  reason: 'late',
  description: 'Arrived two hours late.',
  photos: ['p1'],
};

function setup() {
  const repo = new FakeRepo();
  const attached: string[] = [];
  const photos: EvidencePhotos = {
    attach: (_owner, ids) => Promise.resolve(void attached.push(...ids)),
  };
  const admins: Admins = { canWorkComplaints: (id) => Promise.resolve(id === 'agent') };
  const stamps = { clock: new FakeClock(now), ids: new SequenceIdGenerator(['c1', 'm1']) };
  const store = repo as unknown as ComplaintRepository;
  return {
    repo,
    attached,
    reports: new ReportProblem(store, bookings, photos, stamps),
    queue: new WorkComplaints(store, admins, stamps),
  };
}

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  const err = await p.then(
    () => undefined,
    (e: unknown) => e,
  );
  return err instanceof DomainError ? err.reason : undefined;
}

describe('complaints', () => {
  it('files reports from either side against the other', async () => {
    const { repo, attached, reports } = setup();
    const c = await reports.execute(report);
    expect(c).toMatchObject({ id: 'c1', againstId: 'prov', status: 'open', ticket: 1001 });
    expect(attached).toEqual(['p1']);
    expect(repo.events).toEqual([
      {
        name: 'admin.ComplaintCreated',
        complaintId: 'c1',
        ticketNumber: 'TCK-001001',
        bookingId: 'b1',
        reporterId: 'cust',
        reporterRole: 'customer',
        againstId: 'prov',
      },
    ]);
    const theirs = await reports.execute({
      ...report,
      reporterId: 'prov',
      reporterRole: 'provider',
    });
    expect(theirs.againstId).toBe('cust');
  });

  it('refuses invalid reports, strangers and the wrong role', async () => {
    const { reports } = setup();
    expect(await reason(reports.execute({ ...report, reason: 'rude' }))).toBe(
      AdminErrors.ComplaintInvalid,
    );
    expect(await reason(reports.execute({ ...report, bookingId: 'x' }))).toBe(
      AdminErrors.BookingNotFound,
    );
    expect(await reason(reports.execute({ ...report, reporterRole: 'provider' }))).toBe(
      AdminErrors.BookingNotFound,
    );
  });

  it('assigns, comments and resolves once', async () => {
    const { repo, reports, queue } = setup();
    await reports.execute(report);
    expect(
      await queue.list({ status: null, assigneeId: null, after: null, limit: 2 }),
    ).toHaveLength(1);
    expect(await reason(queue.assign('c1', 'customer'))).toBe(AdminErrors.AssigneeInvalid);
    expect((await queue.assign('c1', 'agent')).assigneeId).toBe('agent');
    const noted = await queue.comment('c1', 'agent', 'Called the provider.');
    expect(noted.comments).toEqual([
      { id: 'm1', complaintId: 'c1', authorId: 'agent', body: 'Called the provider.', at: now },
    ]);
    expect(await reason(queue.comment('nope', 'agent', 'x'))).toBe(AdminErrors.ComplaintNotFound);
    expect(await reason(queue.resolve('c1', 'agent', ' ok ', false))).toBe(
      AdminErrors.ComplaintInvalid,
    );
    const done = await queue.resolve('c1', 'agent', 'Provider warned.', true);
    expect(done).toMatchObject({ status: 'resolved', verified: true, resolvedAt: now });
    expect(repo.events.at(-1)).toEqual({
      name: 'admin.ComplaintResolved',
      complaintId: 'c1',
      ticketNumber: 'TCK-001001',
      bookingId: 'b1',
      reporterId: 'cust',
      reporterRole: 'customer',
      againstId: 'prov',
      verified: true,
      actorId: 'agent',
    });
    expect(await reason(queue.resolve('c1', 'agent', 'Again and again.', false))).toBe(
      AdminErrors.AlreadyResolved,
    );
    expect(await reason(queue.assign('c1', 'agent'))).toBe(AdminErrors.AlreadyResolved);
    expect((await queue.get('c1')).status).toBe('resolved');
  });
});
