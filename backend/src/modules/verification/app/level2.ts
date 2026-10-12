import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import {
  type Level2ResultRecorded,
  type Level2SessionScheduled,
  VerificationEvents,
} from '../contract/events';
import { type Outcome, recorded, retryAfter, type Session } from '../domain/level2';
import { VerificationReasons } from '../domain/reasons';
import { MEDIA, type Media, SETTINGS, type Settings } from '../port/peers';
import { type Page, type SessionFilter } from '../port/repository';
import { States } from './states';

/** A session to book. */
export interface Booking {
  readonly providerId: string;
  readonly serviceId: string;
  readonly at: Date;
  readonly location: string;
}

/** Level 2 interviews, skill tests and supervised jobs (PRD §6.3, A-04). */
@Injectable()
export class Level2Sessions {
  constructor(
    private readonly states: States,
    @Inject(MEDIA) private readonly media: Media,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}

  /** Books a session for a Level 1 provider outside cooling-off. */
  async schedule(b: Booking): Promise<Session> {
    const location = b.location.trim();
    const now = this.states.clock.now();
    if (location === '' || b.at <= now) {
      throw new DomainError(VerificationReasons.Invalid);
    }
    const rules = await this.settings.rules();
    await this.states.catalog.service(b.serviceId);
    const session: Session = {
      id: this.states.ids.newId(),
      providerId: b.providerId,
      serviceId: b.serviceId,
      scheduledAt: b.at,
      location,
      status: 'scheduled',
      result: '',
      checklist: [],
      notes: '',
      visitLat: null,
      visitLng: null,
      photos: [],
      decidedBy: null,
      decidedAt: null,
      createdAt: now,
    };
    await this.states.repo.change(b.providerId, (st) => {
      if (st.level !== 1) {
        throw new DomainError(VerificationReasons.NotEligible);
      }
      if (retryAfter(st.sessions, rules.level2CoolingOffMs, now) !== null) {
        throw new DomainError(VerificationReasons.CoolingOff);
      }
      st.sessions.push(session);
      return [scheduled(session)];
    });
    return session;
  }

  /** Sessions, newest first. */
  list(f: SessionFilter, p: Page): Promise<Session[]> {
    return this.states.repo.sessions(f, p);
  }

  /** One session. */
  get(id: string): Promise<Session> {
    return this.states.repo.session(id);
  }

  /**
   * Closes a session; a pass raises the provider to Level 2, a fail starts the
   * cooling-off period (PRD §6.3).
   */
  async record(sessionId: string, actor: string, o: Outcome): Promise<Session> {
    const loaded = await this.states.repo.session(sessionId);
    for (const photo of o.photos) {
      await this.media.attach(loaded.providerId, photo, ['level2_photo']);
    }
    const now = this.states.clock.now();
    let out = loaded;
    await this.states.change(loaded.providerId, `level2_${o.result}`, (st) => {
      const current = st.sessions.find((s) => s.id === sessionId) ?? loaded;
      const done = recorded(current, now, actor, o);
      if (typeof done === 'string') {
        throw new DomainError(done);
      }
      st.sessions = st.sessions.map((s) => (s.id === sessionId ? done : s));
      st.level2PassedAt = o.result === 'pass' ? now : st.level2PassedAt;
      out = done;
      return [resultRecorded(done, actor)];
    });
    return out;
  }
}

function scheduled(s: Session): Level2SessionScheduled {
  return {
    name: VerificationEvents.Level2SessionScheduled,
    providerId: s.providerId,
    sessionId: s.id,
    scheduledAt: s.scheduledAt.toISOString().replace(/\.\d{3}Z$/, 'Z'),
    location: s.location,
  };
}

function resultRecorded(s: Session, actor: string): Level2ResultRecorded {
  return {
    name: VerificationEvents.Level2ResultRecorded,
    providerId: s.providerId,
    sessionId: s.id,
    result: s.result,
    actorId: actor,
  };
}
