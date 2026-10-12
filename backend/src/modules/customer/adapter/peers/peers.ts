import { Injectable } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { LazyContract } from '../../../../platform/di/lazy-contract';
import { DomainError, isDomainError } from '../../../../platform/errors/domain-error';
import { ADMIN_SERVICE, type AdminService } from '../../../admin/contract/admin-service';
import {
  IDENTITY_SERVICE,
  type IdentityService,
} from '../../../identity/contract/identity-service';
import { MediaPurpose } from '../../../media/contract/dto';
import { MediaErrors } from '../../../media/contract/errors';
import { MEDIA_SERVICE, type MediaService } from '../../../media/contract/media-service';
import { CustomerReasons } from '../../app/errors';
import { type Accounts, type LaunchArea, type Photos } from '../../port/peers';

// Peer contracts are resolved on first use, so customer starts whichever modules are
// wired and the admin console's dependency on customer cannot form a cycle.

/** Profile photos through the media contract. */
@Injectable()
export class MediaPhotos implements Photos {
  private readonly media: LazyContract<MediaService>;

  constructor(moduleRef: ModuleRef) {
    this.media = new LazyContract(moduleRef, MEDIA_SERVICE);
  }

  async attachAvatar(ownerId: string, mediaId: string): Promise<void> {
    const o = await this.media
      .get()
      .getObject(mediaId)
      .catch((err: unknown) => {
        if (isDomainError(err, MediaErrors.NotFound)) {
          return undefined;
        }
        throw err;
      });
    if (o?.ownerId !== ownerId || o.purpose !== MediaPurpose.Avatar || !o.confirmed) {
      throw new DomainError(CustomerReasons.InvalidPhoto);
    }
    await this.media.get().markAttached(mediaId);
  }

  async url(viewerId: string, mediaId: string): Promise<string> {
    const view = await this.media.get().getViewUrl({ mediaId, viewerId, viewerRole: 'customer' });
    return view.url;
  }
}

/** Phone and status through the identity contract. */
@Injectable()
export class IdentityAccounts implements Accounts {
  private readonly identity: LazyContract<IdentityService>;

  constructor(moduleRef: ModuleRef) {
    this.identity = new LazyContract(moduleRef, IDENTITY_SERVICE);
  }

  async account(accountId: string): Promise<{ phone: string; status: string }> {
    const a = await this.identity.get().getAccount(accountId);
    return { phone: a.phone, status: a.status };
  }
}

/** The launch area through the admin settings. */
@Injectable()
export class AdminLaunchArea implements LaunchArea {
  private readonly admin: LazyContract<AdminService>;

  constructor(moduleRef: ModuleRef) {
    this.admin = new LazyContract(moduleRef, ADMIN_SERVICE);
  }

  async geoJson(): Promise<string> {
    return (await this.admin.get().getSettings()).serviceAreaGeoJson;
  }
}
