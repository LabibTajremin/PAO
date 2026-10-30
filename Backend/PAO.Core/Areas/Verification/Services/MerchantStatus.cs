using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>The merchant's verification screen (M14/P-03), submission, and reactions to profile and account changes.</summary>
public sealed class MerchantStatus(VerificationStates states, VerificationPeers peers, IMapper mapper)
{
    // The item each saved profile step puts back into review.
    private static readonly Dictionary<string, string> StepItems = new(StringComparer.Ordinal)
    {
        [EnrolmentStep.Personal] = ItemType.Address,
        [EnrolmentStep.Services] = ItemType.ServiceArea,
        [EnrolmentStep.Area] = ItemType.ServiceArea,
        [EnrolmentStep.EmergencyContact] = ItemType.EmergencyContact,
        [EnrolmentStep.CodeOfConduct] = ItemType.CodeOfConduct,
    };

    /// <summary>The merchant's items, level and Level 2 situation.</summary>
    public async Task<VerificationStatusView> Status(Guid id, CancellationToken cancellationToken)
    {
        var st = await states.Load(id, cancellationToken);
        var settings = await peers.Settings(cancellationToken);
        var retry = VerificationRules.RetryAfter(st.Sessions, settings.Level2CoolingOff, states.Now);
        var next = st.Sessions.FindLast(s => s.Status == "scheduled");
        return new VerificationStatusView
        {
            Level = st.Level,
            Badge = st.Level switch { 2 => "verified_pro", 1 => "verified", _ => "none" },
            Items = [.. ItemType.All.Select(t => mapper.Map<ItemState, VerificationItemView>(st.ItemOf(t)))],
            CanReceiveBookings = VerificationRules.CanReceiveBookings(st, 1),
            Level2 = new Level2InfoView
            {
                Eligible = st.Level == 1 && retry is null,
                RetryAfter = VerificationMappingProfile.Iso(retry),
                NextSession = next is null ? null : mapper.Map<Level2SessionState, Level2SessionView>(next),
            },
        };
    }

    /// <summary>Sends the enrolment to the review queue once every required step is done.</summary>
    public async Task<VerificationStatusView> Submit(Guid id, CancellationToken cancellationToken)
    {
        await peers.MarkSubmitted(id, cancellationToken);
        var merchant = await peers.Merchant(id, cancellationToken);
        var now = states.Now;
        await states.Change(id, null, st =>
        {
            st.SubmittedAt = now;
            st.ServiceIds = merchant.ServiceIds;
            return [];
        }, cancellationToken);
        return await Status(id, cancellationToken);
    }

    /// <summary>
    /// Puts the item matching a saved profile step back into review and keeps the service list
    /// used by the queue filter current; other steps change nothing.
    /// </summary>
    public async Task StepSaved(Guid id, string step, CancellationToken cancellationToken)
    {
        if (!StepItems.TryGetValue(step, out var item))
        {
            return;
        }
        var merchant = await peers.Merchant(id, cancellationToken);
        var now = states.Now;
        await states.Change(id, "resubmitted", st =>
        {
            st.Items[item] = VerificationRules.Submitted(st.ItemOf(item), now, new Dictionary<string, string>(), null);
            st.ServiceIds = merchant.ServiceIds;
            // A changed name or birth date must match the NID again (PRD §6.4).
            var nid = st.ItemOf(ItemType.Nid);
            if (step == EnrolmentStep.Personal && nid.Status != ItemStatus.Missing)
            {
                st.Items[ItemType.Nid] = VerificationRules.Submitted(nid, now, nid.Fields, null);
            }
            return [];
        }, cancellationToken);
    }
}
