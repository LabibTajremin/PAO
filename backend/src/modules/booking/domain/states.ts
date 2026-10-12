/** Booking states (docs/booking-states.md). */
export const Status = {
  Requested: 'requested',
  Accepted: 'accepted',
  OnTheWay: 'on_the_way',
  Arrived: 'arrived',
  InProgress: 'in_progress',
  Completed: 'completed',
  Rejected: 'rejected',
  TimedOut: 'timed_out',
  Cancelled: 'cancelled',
} as const;

/** A booking state. */
export type Status = (typeof Status)[keyof typeof Status];

/** Who moves a booking. */
export const Actor = {
  Customer: 'customer',
  Provider: 'provider',
  System: 'system',
} as const;

/** One of {@link Actor}. */
export type Actor = (typeof Actor)[keyof typeof Actor];

const { Customer, Provider, System } = Actor;

type Table = Readonly<Partial<Record<string, Readonly<Partial<Record<string, readonly Actor[]>>>>>>;

// The table in docs/booking-states.md: from → to → allowed actors.
const transitions: Table = {
  requested: {
    accepted: [Provider],
    rejected: [Provider],
    timed_out: [System],
    cancelled: [Customer],
  },
  accepted: { on_the_way: [Provider], cancelled: [Customer, Provider] },
  on_the_way: { arrived: [Provider], cancelled: [Customer, Provider] },
  arrived: { in_progress: [Provider], cancelled: [Customer, Provider] },
  in_progress: { completed: [Provider] },
};

/** Reports whether `actor` may move a booking from one state to another. */
export function canTransition(from: string, to: string, actor: string): boolean {
  return transitions[from]?.[to]?.some((a) => a === actor) ?? false;
}

/** States that hold the provider: they count against the one-active-job rule. */
export const ACTIVE: readonly Status[] = [
  Status.Accepted,
  Status.OnTheWay,
  Status.Arrived,
  Status.InProgress,
];

/** States shown on the upcoming tab. */
export const UPCOMING: readonly Status[] = [Status.Requested, ...ACTIVE];

/** States that ended the booking. */
export const PAST: readonly Status[] = [
  Status.Completed,
  Status.Rejected,
  Status.TimedOut,
  Status.Cancelled,
];
