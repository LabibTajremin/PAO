using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Earnings.Queries;

/// <summary>The provider's totals per Asia/Dhaka day over the period containing `Date` (default today, P-08).</summary>
public sealed record GetEarningsSummary(Guid ProviderId, string Period, string? Date) : IQuery<EarningsSummaryView>;

/// <summary>Completed jobs between two Dhaka dates (inclusive); open ends default to the current month.</summary>
public sealed record ListEarningsJobs(Guid ProviderId, string? From, string? To, string? Cursor, int? Limit) : IQuery<EarningsJobListView>;

/// <summary>Checks <see cref="GetEarningsSummary"/>.</summary>
public sealed class GetEarningsSummaryValidator : AbstractValidator<GetEarningsSummary>
{
    /// <summary>`day`, `week` or `month`, as `booking.invalid` otherwise.</summary>
    public GetEarningsSummaryValidator() => RuleFor(r => r.Period).Custom((period, _) =>
    {
        if (EarningsCalendar.Period(period, new DateOnly(2026, 1, 1)) is null)
        {
            throw new DomainException(BookingReasons.Invalid);
        }
    });
}

/// <summary>Checks <see cref="ListEarningsJobs"/>.</summary>
public sealed class ListEarningsJobsValidator : AbstractValidator<ListEarningsJobs>
{
    /// <summary>The spec has checked the formats.</summary>
    public ListEarningsJobsValidator() => RuleFor(r => r.ProviderId).NotEmpty();
}

/// <summary>Answers <see cref="GetEarningsSummary"/>; every day of the period appears, days without jobs as zeros.</summary>
public sealed class GetEarningsSummaryHandler(BookingAccess access) : IRequestHandler<GetEarningsSummary, EarningsSummaryView>
{
    /// <inheritdoc />
    public async Task<EarningsSummaryView> Handle(GetEarningsSummary request, CancellationToken cancellationToken)
    {
        var day = EarningsCalendar.Parse(request.Date) ?? EarningsCalendar.DhakaDay(access.Now);
        var (from, to) = EarningsCalendar.Period(request.Period, day)!.Value;
        var (start, until) = EarningsCalendar.Range(from, to);
        var byDay = (await access.Queries.EarningsByDay(request.ProviderId, start, until, cancellationToken)).ToDictionary(d => d.Day);
        var buckets = EarningsCalendar.Days(from, to)
            .Select(d => byDay.GetValueOrDefault(d) ?? new EarningsDay(d, 0, 0))
            .Select(d => new EarningsBucketView { Date = EarningsCalendar.Iso(d.Day), Jobs = d.Jobs, Total = d.Total })
            .ToList();
        return new EarningsSummaryView
        {
            Period = request.Period,
            From = EarningsCalendar.Iso(from),
            To = EarningsCalendar.Iso(to),
            Total = buckets.Sum(b => b.Total),
            Jobs = buckets.Sum(b => b.Jobs),
            Buckets = buckets,
        };
    }
}

/// <summary>Answers <see cref="ListEarningsJobs"/>.</summary>
public sealed class ListEarningsJobsHandler(BookingAccess access, IMapper mapper) : IRequestHandler<ListEarningsJobs, EarningsJobListView>
{
    /// <inheritdoc />
    public async Task<EarningsJobListView> Handle(ListEarningsJobs request, CancellationToken cancellationToken)
    {
        var (size, page) = BookingPaging.Page(request.Cursor, request.Limit);
        var month = EarningsCalendar.Month(EarningsCalendar.DhakaDay(access.Now));
        var (from, until) = EarningsCalendar.Range(EarningsCalendar.Parse(request.From) ?? month.From, EarningsCalendar.Parse(request.To) ?? month.To);
        var rows = await access.Queries.EarningsJobs(request.ProviderId, from, until, page, cancellationToken);
        return new EarningsJobListView
        {
            Items = mapper.MapAll<EarningsJob, EarningsJobView>(rows.Take(size)),
            NextCursor = BookingPaging.Next(rows, size, r => (r.CompletedAt, r.Id)),
        };
    }
}
