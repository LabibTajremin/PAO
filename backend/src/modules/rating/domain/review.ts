/** Why a review was refused; the HTTP adapter maps them to API errors. */
export const RatingReasons = {
  NotAllowed: 'rating.not_allowed',
  AlreadyReviewed: 'rating.already_reviewed',
  Invalid: 'rating.invalid',
} as const;

/** A reason a review was refused. */
export type RatingReason = (typeof RatingReasons)[keyof typeof RatingReasons];

/** A value in English and Bangla. */
export interface Text {
  readonly en: string;
  readonly bn: string;
}

/** The two sides of a booking, as authors and subjects of reviews. */
export const ReviewRole = {
  Customer: 'customer',
  Provider: 'provider',
} as const;

/** A side of a booking. */
export type ReviewRole = (typeof ReviewRole)[keyof typeof ReviewRole];

/** A completed booking; only these may be reviewed. */
export interface Reviewable {
  readonly bookingId: string;
  readonly customerId: string;
  readonly providerId: string;
  readonly customerName: string;
  readonly providerName: string;
  readonly serviceName: Text;
  readonly completedAt: Date;
}

/** One side's rating of the other. */
export interface Review {
  readonly id: string;
  readonly bookingId: string;
  readonly authorId: string;
  readonly authorRole: ReviewRole;
  readonly authorName: string;
  readonly subjectId: string;
  readonly stars: number;
  readonly tags: readonly string[];
  readonly comment: string;
  readonly serviceName: Text;
  readonly createdAt: Date;
}

/** What an author says about a booking. */
export interface ReviewInput {
  readonly stars: number;
  readonly tags: readonly string[];
  readonly comment: string;
}

/** A checked review that has no id or time yet. */
export type NewReview = Omit<Review, 'id' | 'createdAt'>;

/** The role of the person being reviewed. */
export function subjectRole(authorRole: ReviewRole): ReviewRole {
  return authorRole === ReviewRole.Customer ? ReviewRole.Provider : ReviewRole.Customer;
}

/** Reviewers' privacy: only the first word of a name is shown. */
export function firstName(name: string): string {
  return name.trim().split(/\s+/)[0] ?? '';
}

function valid(r: ReviewInput): boolean {
  const stars = Number.isInteger(r.stars) && r.stars >= 1 && r.stars <= 5;
  const distinct = new Set(r.tags).size === r.tags.length;
  return stars && r.tags.length <= 6 && distinct && Array.from(r.comment).length <= 500;
}

/**
 * Returns the review, or why it is refused: the author must be that side of the
 * completed booking, and the review needs 1–5 stars, at most six distinct tags and a comment of at most 500 characters.
 */
export function newReview(
  b: Reviewable,
  author: { readonly id: string; readonly role: ReviewRole },
  input: ReviewInput,
): NewReview | RatingReason {
  const asCustomer = author.role === ReviewRole.Customer && author.id === b.customerId;
  const asProvider = author.role === ReviewRole.Provider && author.id === b.providerId;
  if (!asCustomer && !asProvider) {
    return RatingReasons.NotAllowed;
  }
  const content = { ...input, comment: input.comment.trim() };
  if (!valid(content)) {
    return RatingReasons.Invalid;
  }
  return {
    bookingId: b.bookingId,
    authorId: author.id,
    authorRole: author.role,
    authorName: firstName(asCustomer ? b.customerName : b.providerName),
    subjectId: asCustomer ? b.providerId : b.customerId,
    ...content,
    serviceName: b.serviceName,
  };
}
