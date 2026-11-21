using PAO.Lib.Areas.Rating;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Rating.Services;

/// <summary>Who may review a booking and what a review may say (C-11, P-09).</summary>
public static class RatingRules
{
    /// <summary>Reviewers' privacy: only the first word of a name is shown.</summary>
    public static string FirstName(string name)
    {
        var words = name.Trim().Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries);
        return words.Length == 0 ? string.Empty : words[0];
    }

    /// <summary>
    /// The review, or the reason it is refused: the author must be that side of the
    /// completed booking, with 1–5 stars, at most six distinct tags and a comment of at most
    /// 500 characters. Throws `rating.not_allowed` or `rating.invalid`.
    /// </summary>
    public static Review NewReview(Reviewable b, Guid authorId, string role, ReviewInput input, Guid id, DateTimeOffset now)
    {
        var asCustomer = role == ReviewRole.Customer && authorId == b.CustomerId;
        var asProvider = role == ReviewRole.Provider && authorId == b.ProviderId;
        if (!asCustomer && !asProvider)
        {
            throw new DomainException(RatingReasons.NotAllowed);
        }
        var tags = input.Tags ?? [];
        var comment = (input.Comment ?? string.Empty).Trim();
        var valid = input.Stars is >= 1 and <= 5 && tags.Count <= 6 && tags.Distinct().Count() == tags.Count && comment.EnumerateRunes().Count() <= 500;
        if (!valid)
        {
            throw new DomainException(RatingReasons.Invalid);
        }
        return new Review
        {
            Id = id,
            BookingId = b.BookingId,
            AuthorId = authorId,
            AuthorRole = role,
            AuthorName = FirstName(asCustomer ? b.CustomerName : b.ProviderName),
            SubjectId = asCustomer ? b.ProviderId : b.CustomerId,
            Stars = input.Stars,
            Tags = tags,
            Comment = comment,
            ServiceName = b.ServiceName,
            CreatedAt = now,
        };
    }
}
