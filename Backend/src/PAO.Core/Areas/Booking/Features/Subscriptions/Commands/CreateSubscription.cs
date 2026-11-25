using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Subscriptions.Commands;

/// <summary>
/// A customer orders a scheduled delivery from one merchant (ADR-0041 §2). Like a booking
/// request it writes in its own transaction, so a repeated key returns the stored order.
/// </summary>
public sealed record CreateSubscription(Guid CustomerId, string IdempotencyKey, SubscriptionCreateInput Input) : IRequest<SubscriptionView>;

/// <summary>Checks the shape of <see cref="CreateSubscription"/>; the service's rules are checked against the catalog.</summary>
public sealed class CreateSubscriptionValidator : AbstractValidator<CreateSubscription>
{
    /// <summary>A key, one to ten items, a window, readable dates and a short note.</summary>
    public CreateSubscriptionValidator() => RuleFor(r => r).Custom((r, _) =>
    {
        var i = r.Input;
        var invalid = string.IsNullOrWhiteSpace(r.IdempotencyKey) || i.Items.Count is 0 or > 10 || i.Window is null
            || EarningsCalendar.Parse(i.StartDate) is null || (i.EndDate is not null && EarningsCalendar.Parse(i.EndDate) is null)
            || (i.Note ?? string.Empty).EnumerateRunes().Count() > 500;
        if (invalid)
        {
            throw new DomainException(BookingReasons.Invalid);
        }
    });
}

/// <summary>Answers <see cref="CreateSubscription"/>.</summary>
public sealed class CreateSubscriptionHandler(SubscriptionAccess access, BookingPricing pricing, IMapper mapper) : IRequestHandler<CreateSubscription, SubscriptionView>
{
    /// <inheritdoc />
    public async Task<SubscriptionView> Handle(CreateSubscription request, CancellationToken cancellationToken)
    {
        var input = request.Input;
        var service = await pricing.Scheduled(input.ServiceId, cancellationToken);
        var schedule = service.Schedule ?? throw new DomainException(BookingReasons.NotBookable);
        var plan = Plan(input);
        var window = input.Window!;
        if (!DeliveryCalendar.IsValid(plan, schedule.Patterns) || !schedule.Windows.Contains(window))
        {
            throw new DomainException(BookingReasons.Invalid);
        }
        var lines = await pricing.Lines(service.Id, input.Items, 0, cancellationToken);
        if (lines.Sum(l => l.Quantity) is var quantity && (quantity < schedule.MinQuantity || quantity > schedule.MaxQuantity))
        {
            throw new DomainException(BookingReasons.Invalid);
        }
        await EnsureLeadTime(plan, window, schedule, cancellationToken);
        var (customer, address, provider) = await pricing.Sides(request.CustomerId, input.AddressId, input.ProviderId, service.Id, cancellationToken);
        var subscription = Draft(request, service, schedule, plan, lines, customer, address, provider);
        var stored = await access.Repository.Create(subscription,
            s => access.Event(new SubscriptionRequested { StartDate = EarningsCalendar.Iso(s.Plan.StartDate) }, s), cancellationToken);
        return mapper.Customer(stored, await access.Upcoming(stored, cancellationToken));
    }

    private StoredSubscription Draft(CreateSubscription request, CatalogService service, ServiceSchedule schedule, DeliveryPlan plan,
    List<BookingLine> lines, BookingParty customer, AddressSnapshot address, MerchantProfile provider) => new()
    {
        Id = access.NewId(),
        Customer = customer,
        Provider = new BookingParty(provider.Id, provider.FullName, provider.Phone),
        ServiceId = service.Id,
        ServiceName = service.Name,
        Address = address,
        Note = (request.Input.Note ?? string.Empty).Trim(),
        Lines = lines,
        TotalPaisa = BookingStates.Total(lines),
        Unit = schedule.Unit,
        Plan = plan,
        Window = request.Input.Window!,
        Cutoff = schedule.CutoffTime,
        Status = SubscriptionStatus.Requested,
        IdempotencyKey = request.IdempotencyKey,
        CreatedAt = access.Now,
    };

    private static DeliveryPlan Plan(SubscriptionCreateInput input) => new()
    {
        Pattern = input.Pattern,
        Weekdays = input.Weekdays ?? [],
        DayOfMonth = input.DayOfMonth,
        StartDate = EarningsCalendar.Parse(input.StartDate)!.Value,
        EndDate = EarningsCalendar.Parse(input.EndDate),
        Count = input.Count,
    };

    /// <summary>The first date must leave the service's lead time and be before its cutoff.</summary>
    private async Task EnsureLeadTime(DeliveryPlan plan, DeliveryWindow window, ServiceSchedule schedule, CancellationToken cancellationToken)
    {
        var holidays = await access.Holidays(cancellationToken);
        var first = DeliveryCalendar.Dates(plan, plan.StartDate.AddDays(400), holidays).Cast<DateOnly?>().FirstOrDefault()
            ?? throw new DomainException(BookingReasons.Invalid);
        var now = access.Now;
        if (DeliveryCalendar.At(first, window.From) - now < TimeSpan.FromHours(schedule.LeadHours) || now >= DeliveryCalendar.Cutoff(first, schedule.CutoffTime))
        {
            throw new DomainException(BookingReasons.LeadTime);
        }
    }
}
