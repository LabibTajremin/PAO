using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Rating.Features.Reviews.Commands;
using PAO.Core.Areas.Rating.Features.Reviews.Queries;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Rating.Controllers;

/// <summary>Rating failures as API errors, equal to the Go and NestJS map.</summary>
public sealed class RatingErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [RatingReasons.NotAllowed] = new(409, "REVIEW_NOT_ALLOWED", "You can review only your own completed bookings."),
        [RatingReasons.AlreadyReviewed] = new(409, "REVIEW_ALREADY_SUBMITTED", "You already reviewed this booking."),
        [RatingReasons.Invalid] = new(422, "VALIDATION_FAILED", "Check the review and try again."),
    };
}

/// <summary>The customer's side: rating the provider and reading a provider's reviews (C-11, C42).</summary>
[ApiController]
[Area("Rating")]
[Route("v1/customer")]
[ErrorMap(typeof(RatingErrorMap))]
public sealed class CustomerReviewsController(IMediator mediator) : ControllerBase
{
    /// <summary>reviewProvider.</summary>
    [HttpPost("bookings/{bookingId}/review")]
    [AllUserType(Permission = "review:create")]
    public async Task<IActionResult> Review(Guid bookingId, [FromBody] ReviewInput body) =>
        StatusCode(201, await mediator.Send(new SubmitReview(HttpContext.Caller().AccountId, ReviewRole.Customer, bookingId, body), HttpContext.RequestAborted));

    /// <summary>listProviderReviews.</summary>
    [HttpGet("providers/{providerId}/reviews")]
    [Customer(Permission = "provider:browse")]
    public Task<ReviewListView> List(Guid providerId, [FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListProviderReviews(providerId, cursor, limit), HttpContext.RequestAborted);
}

/// <summary>The provider's side: rating the customer, their reviews and breakdown (P-09, M30).</summary>
[ApiController]
[Area("Rating")]
[Route("v1/provider")]
[ErrorMap(typeof(RatingErrorMap))]
public sealed class ProviderReviewsController(IMediator mediator) : ControllerBase
{
    /// <summary>reviewCustomer.</summary>
    [HttpPost("jobs/{bookingId}/review")]
    [AllUserType(Permission = "review:create")]
    public async Task<IActionResult> Review(Guid bookingId, [FromBody] ReviewInput body) =>
        StatusCode(201, await mediator.Send(new SubmitReview(HttpContext.Caller().AccountId, ReviewRole.Provider, bookingId, body), HttpContext.RequestAborted));

    /// <summary>listMyReviews.</summary>
    [HttpGet("reviews")]
    [Merchant(Permission = "provider:manage:own")]
    public Task<ReviewListView> List([FromQuery] string? cursor, [FromQuery] int? limit) =>
        mediator.Send(new ListProviderReviews(HttpContext.Caller().AccountId, cursor, limit), HttpContext.RequestAborted);

    /// <summary>getMyRating.</summary>
    [HttpGet("rating")]
    [Merchant(Permission = "provider:manage:own")]
    public Task<RatingBreakdownView> Rating() => mediator.Send(new GetMyRating(HttpContext.Caller().AccountId), HttpContext.RequestAborted);
}
