import { AdminEvents, type ComplaintResolved, type SettingChanged } from '../../admin/contract';
import { CatalogEvents, type PriceChanged } from '../../catalog/contract';
import { type AccountStatusChanged, IdentityEvents } from '../../identity/contract';
import {
  type DocumentApproved,
  type DocumentExpired,
  type DocumentRejected,
  type Level2ResultRecorded,
  type ProviderLevelChanged,
  VerificationEvents,
} from '../../verification/contract';
import { type NewEntry } from './audit-log';

const entry = (e: Partial<NewEntry> & Pick<NewEntry, 'action' | 'subjectType' | 'subjectId'>) => ({
  actorId: null,
  actorRole: '',
  reason: '',
  before: null,
  after: null,
  ...e,
});

const verifier = (actorId: string | null) => ({ actorId, actorRole: 'verifier' });

/**
 * Turns each audited event into its entry. Every event that changes a person's status, a
 * price or a decision is audited (docs/build/02-architecture.md §8); verification
 * decisions record who, when, what and why (PRD §6.4).
 */
export const EVENT_ENTRIES: Readonly<Record<string, (payload: never) => NewEntry>> = {
  [IdentityEvents.AccountStatusChanged]: (e: AccountStatusChanged) =>
    entry({
      actorId: e.actorId,
      action: 'account.status_changed',
      subjectType: 'account',
      subjectId: e.accountId,
      reason: e.reason,
      before: { status: e.from },
      after: { status: e.to },
    }),
  [CatalogEvents.PriceChanged]: (e: PriceChanged) =>
    entry({
      actorId: e.actorId,
      action: 'catalog.price_changed',
      subjectType: 'sub_service',
      subjectId: e.subServiceId,
      after: { amountPaisa: e.amountPaisa, priceVersionId: e.priceVersionId },
    }),
  [AdminEvents.SettingChanged]: (e: SettingChanged) =>
    entry({
      actorId: e.actorId,
      action: 'settings.changed',
      subjectType: 'setting',
      subjectId: e.key,
      before: { value: e.before },
      after: { value: e.after },
    }),
  [AdminEvents.ComplaintResolved]: (e: ComplaintResolved) =>
    entry({
      actorId: e.actorId,
      action: 'complaint.resolved',
      subjectType: 'complaint',
      subjectId: e.complaintId,
      after: { ticket: e.ticketNumber, verified: e.verified, againstId: e.againstId },
    }),
  [VerificationEvents.DocumentApproved]: (e: DocumentApproved) =>
    entry({
      ...verifier(e.actorId),
      action: 'verification.item_approved',
      subjectType: 'provider',
      subjectId: e.providerId,
      after: { item: e.item, status: 'approved' },
    }),
  [VerificationEvents.DocumentRejected]: (e: DocumentRejected) =>
    entry({
      ...verifier(e.actorId),
      action: 'verification.item_rejected',
      subjectType: 'provider',
      subjectId: e.providerId,
      reason: e.reason,
      after: { item: e.item, status: 'rejected' },
    }),
  [VerificationEvents.ProviderLevelChanged]: (e: ProviderLevelChanged) =>
    entry({
      action: 'verification.level_changed',
      subjectType: 'provider',
      subjectId: e.providerId,
      reason: e.reason,
      before: { level: e.from },
      after: { level: e.to },
    }),
  [VerificationEvents.Level2ResultRecorded]: (e: Level2ResultRecorded) =>
    entry({
      ...verifier(e.actorId),
      action: 'verification.level2_result',
      subjectType: 'provider',
      subjectId: e.providerId,
      after: { session: e.sessionId, result: e.result },
    }),
  [VerificationEvents.DocumentExpired]: (e: DocumentExpired) =>
    entry({
      action: 'verification.item_expired',
      subjectType: 'provider',
      subjectId: e.providerId,
      after: { item: e.item, status: 'expired' },
    }),
};
