using System.Globalization;
using PAO.Core.Areas.Verification.Repositories;
using PAO.Lib.Areas.Media;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>Level 2 interviews, skill tests and supervised jobs (PRD §6.3, A-04).</summary>
public sealed class Level2Sessions(VerificationStates states, VerificationPeers peers, VerificationRepository repository)
{
    /// <summary>Books a session for a Level 1 merchant outside cooling-off.</summary>
    public async Task<Level2SessionState> Schedule(Level2SessionInput input, CancellationToken cancellationToken)
    {
        var location = input.Location.Trim();
        var now = states.Now;
        if (location.Length == 0 || input.ScheduledAt <= now)
        {
            throw new DomainException(VerificationReasons.Invalid);
        }
        var settings = await peers.Settings(cancellationToken);
        await peers.Service(input.ServiceId, cancellationToken);
        var session = new Level2SessionState
        {
            Id = states.NewId(),
            ProviderId = input.ProviderId,
            ServiceId = input.ServiceId,
            ScheduledAt = input.ScheduledAt,
            Location = location,
            Status = "scheduled",
            CreatedAt = now,
        };
        await states.Change(input.ProviderId, null, st =>
        {
            if (st.Level != 1)
            {
                throw new DomainException(VerificationReasons.NotEligible);
            }
            if (VerificationRules.RetryAfter(st.Sessions, settings.Level2CoolingOff, now) is not null)
            {
                throw new DomainException(VerificationReasons.CoolingOff);
            }
            st.Sessions.Add(session);
            return [Scheduled(session)];
        }, cancellationToken);
        return session;
    }

    /// <summary>
    /// Closes a session; a pass raises the merchant to Level 2, a fail starts the cooling-off
    /// period (PRD §6.3).
    /// </summary>
    public async Task<Level2SessionState> Record(Guid sessionId, Guid actor, Level2Outcome outcome, CancellationToken cancellationToken)
    {
        var loaded = await repository.Session(sessionId, cancellationToken);
        foreach (var photo in outcome.Photos)
        {
            await peers.Attach(loaded.ProviderId, photo, [MediaPurpose.Level2Photo], cancellationToken);
        }
        var now = states.Now;
        var done = loaded;
        await states.Change(loaded.ProviderId, $"level2_{outcome.Result}", st =>
        {
            var current = st.Sessions.Find(s => s.Id == sessionId)!;
            done = VerificationRules.Recorded(current, now, actor, outcome);
            st.Sessions = [.. st.Sessions.Select(s => s.Id == sessionId ? done : s)];
            st.Level2PassedAt = outcome.Result == "pass" ? now : st.Level2PassedAt;
            return [new Level2ResultRecorded { ProviderId = done.ProviderId, SessionId = done.Id, Result = done.Result, ActorId = actor }];
        }, cancellationToken);
        return done;
    }

    private static Level2SessionScheduled Scheduled(Level2SessionState s) => new()
    {
        ProviderId = s.ProviderId,
        SessionId = s.Id,
        // NestJS dropped the milliseconds: "2026-10-20T10:00:00Z".
        ScheduledAt = s.ScheduledAt.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture),
        Location = s.Location,
    };
}
