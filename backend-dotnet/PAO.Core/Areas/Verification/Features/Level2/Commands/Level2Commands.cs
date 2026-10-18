using PAO.Core.Areas.Verification.Services;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Features.Level2.Commands;

/// <summary>scheduleLevel2Session (A-04).</summary>
public sealed record ScheduleLevel2Session(Level2SessionInput Input) : ICommand<Level2SessionView>;

/// <summary>recordLevel2Result: closes the session; a pass raises the merchant to Level 2.</summary>
public sealed record RecordLevel2Result(Guid Session, Guid Verifier, Level2ResultInput Input) : ICommand<Level2SessionView>;

/// <summary>Answers <see cref="ScheduleLevel2Session"/>.</summary>
public sealed class ScheduleLevel2SessionHandler(Level2Sessions sessions, IMapper mapper) : IRequestHandler<ScheduleLevel2Session, Level2SessionView>
{
    /// <inheritdoc />
    public async Task<Level2SessionView> Handle(ScheduleLevel2Session request, CancellationToken cancellationToken) =>
        mapper.Map<Level2SessionState, Level2SessionView>(await sessions.Schedule(request.Input, cancellationToken));
}

/// <summary>Answers <see cref="RecordLevel2Result"/>.</summary>
public sealed class RecordLevel2ResultHandler(Level2Sessions sessions, IMapper mapper) : IRequestHandler<RecordLevel2Result, Level2SessionView>
{
    /// <inheritdoc />
    public async Task<Level2SessionView> Handle(RecordLevel2Result request, CancellationToken cancellationToken)
    {
        var b = request.Input;
        var outcome = new Level2Outcome
        {
            Result = b.Result,
            Checklist = b.Checklist,
            Notes = b.Notes ?? string.Empty,
            VisitLat = b.VisitLocation?.Lat,
            VisitLng = b.VisitLocation?.Lng,
            Photos = b.PhotoMediaIds ?? [],
        };
        return mapper.Map<Level2SessionState, Level2SessionView>(await sessions.Record(request.Session, request.Verifier, outcome, cancellationToken));
    }
}
