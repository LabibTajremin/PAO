/** Finds who took part in a booking. */
export interface Bookings {
  /** Returns the booking's parties, or throws `admin.booking_not_found`. */
  parties(bookingId: string): Promise<{ customerId: string; providerId: string }>;
}

/** Attaches evidence photos. */
export interface EvidencePhotos {
  /**
   * Marks the photos attached; throws `admin.photo_invalid` unless every one is the
   * owner's confirmed complaint photo.
   */
  attach(ownerId: string, mediaIds: readonly string[]): Promise<void>;
}

/** Answers who may work the complaints queue. */
export interface Admins {
  canWorkComplaints(accountId: string): Promise<boolean>;
}

/** Injection token for {@link Bookings}. */
export const BOOKINGS = Symbol('AdminBookings');
/** Injection token for {@link EvidencePhotos}. */
export const EVIDENCE_PHOTOS = Symbol('AdminEvidencePhotos');
/** Injection token for {@link Admins}. */
export const ADMINS = Symbol('AdminAdmins');
