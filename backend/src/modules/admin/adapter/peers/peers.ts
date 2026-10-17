import { Inject, Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { DomainError, isDomainError } from '../../../../platform/errors/domain-error';
import { BookingErrors } from '../../../booking/contract/errors';
import { AccountStatus, Role } from '../../../identity/contract/dto';
import { IdentityErrors } from '../../../identity/contract/errors';
import { MediaPurpose } from '../../../media/contract/dto';
import { MediaErrors } from '../../../media/contract/errors';
import { MEDIA_SERVICE, type MediaService } from '../../../media/contract/media-service';
import { AdminErrors } from '../../app/errors';
import { CONSOLE, type Console } from '../../port/console';
import { type Admins, type Bookings, type EvidencePhotos } from '../../port/peers';

// Media is resolved on first use like the console's contracts, so admin starts
// whichever modules are wired.

/** Finds a booking's parties through the booking contract. */
@Injectable()
export class BookingParties implements Bookings {
  constructor(@Inject(CONSOLE) private readonly console: Console) {}

  async parties(bookingId: string): Promise<{ customerId: string; providerId: string }> {
    try {
      const b = await this.console.bookings().getBooking(bookingId);
      return { customerId: b.customerId, providerId: b.providerId };
    } catch (err) {
      if (isDomainError(err, BookingErrors.NotFound)) {
        throw new DomainError(AdminErrors.BookingNotFound, { cause: err });
      }
      throw err;
    }
  }
}

/** Checks and attaches complaint photos through the media contract. */
@Injectable()
export class MediaEvidencePhotos implements EvidencePhotos {
  private readonly media: LazyContract<MediaService>;

  constructor(moduleRef: ModuleRef) {
    this.media = new LazyContract(moduleRef, MEDIA_SERVICE);
  }

  async attach(ownerId: string, mediaIds: readonly string[]): Promise<void> {
    for (const id of mediaIds) {
      await this.check(ownerId, id);
    }
    const failures: unknown[] = [];
    for (const id of mediaIds) {
      await this.media
        .get()
        .markAttached(id)
        .catch((err: unknown) => failures.push(err));
    }
    if (failures.length > 0) {
      throw failures[0];
    }
  }

  private async check(ownerId: string, id: string): Promise<void> {
    const o = await this.media
      .get()
      .getObject(id)
      .catch((err: unknown) => {
        if (isDomainError(err, MediaErrors.NotFound)) {
          return undefined;
        }
        throw err;
      });
    if (o?.ownerId !== ownerId || o.purpose !== MediaPurpose.ComplaintPhoto || !o.confirmed) {
      throw new DomainError(AdminErrors.PhotoInvalid);
    }
  }
}

/** Answers who may work complaints through the identity contract. */
@Injectable()
export class IdentityAdmins implements Admins {
  constructor(@Inject(CONSOLE) private readonly console: Console) {}

  async canWorkComplaints(accountId: string): Promise<boolean> {
    try {
      const a = await this.console.identity().getAccount(accountId);
      return (
        a.status === AccountStatus.Active &&
        (a.roles.includes(Role.SupportAgent) || a.roles.includes(Role.SuperAdmin))
      );
    } catch (err) {
      if (isDomainError(err, IdentityErrors.AccountNotFound)) {
        return false;
      }
      throw err;
    }
  }
}
