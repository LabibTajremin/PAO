using FluentValidation;
using PAO.Core.Areas.Rating.Repositories;
using PAO.Core.Areas.Rating.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Rating.Features.Reviews.Commands;

/// <summary>One side's review of a completed booking, once per side (C-11, P-09).</summary>
public sealed record SubmitReview(Guid AuthorId, string Role, Guid BookingId, ReviewInput Input) : ICommand<ReviewView>;

/// <summary>Makes a completed booking reviewable by both sides; sent for `booking.BookingCompleted`.</summary>
public sealed record OpenReviewable(Reviewable Booking) : ICommand;

/// <summary>Drops a deleted account's name and comments; sent for `identity.AccountDeleted`.</summary>
public sealed record EraseReviewAuthor(Guid AccountId) : ICommand;

/// <summary>Checks <see cref="SubmitReview"/>.</summary>
public sealed class SubmitReviewValidator : AbstractValidator<SubmitReview>
{
    /// <summary>The author writes as a customer or a provider.</summary>
    public SubmitReviewValidator() => RuleFor(r => r.Role).Must(role => role is ReviewRole.Customer or ReviewRole.Provider);
}

/// <summary>Checks <see cref="OpenReviewable"/>.</summary>
public sealed class OpenReviewableValidator : AbstractValidator<OpenReviewable>
{
    /// <summary>The event carried a booking.</summary>
    public OpenReviewableValidator() => RuleFor(r => r.Booking).NotNull();
}

/// <summary>Checks <see cref="EraseReviewAuthor"/>.</summary>
public sealed class EraseReviewAuthorValidator : AbstractValidator<EraseReviewAuthor>
{
    /// <summary>Any id; a missing one erases nothing.</summary>
    public EraseReviewAuthorValidator() => RuleFor(r => r.AccountId).NotNull();
}

/// <summary>Answers <see cref="SubmitReview"/>; `rating.ReviewSubmitted` carries the new aggregate so subscribers need not call back.</summary>
public sealed class SubmitReviewHandler(RatingRepository repository, IClock clock, IIdGenerator ids, IMapper mapper) : IRequestHandler<SubmitReview, ReviewView>
{
    /// <inheritdoc />
    public async Task<ReviewView> Handle(SubmitReview request, CancellationToken cancellationToken)
    {
        var booking = await repository.Reviewable(request.BookingId, cancellationToken);
        var r = RatingRules.NewReview(booking, request.AuthorId, request.Role, request.Input, ids.NewId(), clock.Now);
        await repository.Submit(r, a => new ReviewSubmitted
        {
            ReviewId = r.Id,
            BookingId = r.BookingId,
            AuthorId = r.AuthorId,
            SubjectId = r.SubjectId,
            SubjectRole = ReviewRole.SubjectOf(r.AuthorRole),
            Stars = r.Stars,
            NewAverage = a.Average,
            NewCount = a.Count,
        }, cancellationToken);
        return mapper.Map<Review, ReviewView>(r);
    }
}

/// <summary>Answers <see cref="OpenReviewable"/>.</summary>
public sealed class OpenReviewableHandler(RatingRepository repository) : IRequestHandler<OpenReviewable, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(OpenReviewable request, CancellationToken cancellationToken)
    {
        await repository.AddReviewable(request.Booking, cancellationToken);
        return Unit.Value;
    }
}

/// <summary>Answers <see cref="EraseReviewAuthor"/>; idempotent under redelivery.</summary>
public sealed class EraseReviewAuthorHandler(RatingRepository repository) : IRequestHandler<EraseReviewAuthor, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(EraseReviewAuthor request, CancellationToken cancellationToken)
    {
        await repository.Erase(request.AccountId, cancellationToken);
        return Unit.Value;
    }
}
