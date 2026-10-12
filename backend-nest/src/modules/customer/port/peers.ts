/** The part of the media contract the profile photo needs. */
export interface Photos {
  /**
   * Checks that `mediaId` is a confirmed avatar upload owned by `ownerId` and marks it
   * attached; throws `customer.invalid_photo` otherwise.
   */
  attachAvatar(ownerId: string, mediaId: string): Promise<void>;
  /** A short-lived URL for showing the photo. */
  url(viewerId: string, mediaId: string): Promise<string>;
}

/** Sign-in details owned by identity. */
export interface Accounts {
  account(accountId: string): Promise<{ phone: string; status: string }>;
}

/** The launch area from the admin settings. */
export interface LaunchArea {
  /** GeoJSON; empty means everywhere. */
  geoJson(): Promise<string>;
}

/** Injection token for {@link Photos}. */
export const PHOTOS = Symbol('CustomerPhotos');
/** Injection token for {@link Accounts}. */
export const ACCOUNTS = Symbol('CustomerAccounts');
/** Injection token for {@link LaunchArea}. */
export const LAUNCH_AREA = Symbol('CustomerLaunchArea');
