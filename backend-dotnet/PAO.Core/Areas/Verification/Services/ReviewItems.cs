using System.Globalization;
using System.Text;
using PAO.Core.Areas.Verification.Repositories;
using PAO.Infrastructure.Crypto;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Errors;
using PAO.Lib.Events;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>The review queue, the review screen and per-item decisions (A-03, A06).</summary>
public sealed class ReviewItems(VerificationStates states, VerificationPeers peers, DataCipher cipher, IMapper mapper)
{
    /// <summary>
    /// Submitted merchants with pending items, oldest first. Services come from one catalog
    /// read for the page; names come from the Merchant contract, which reads one merchant at
    /// a time (at most a page).
    /// </summary>
    public async Task<IReadOnlyList<VerificationQueueItemView>> Queue(IReadOnlyList<QueueRow> rows, CancellationToken cancellationToken)
    {
        var catalog = rows.Count == 0 ? [] : (await peers.Services(cancellationToken)).ToDictionary(s => s.Id);
        var now = states.Now;
        var items = new List<VerificationQueueItemView>(rows.Count);
        foreach (var r in rows)
        {
            var merchant = await peers.Merchant(r.ProviderId, cancellationToken);
            var services = new List<ServiceRefView>(r.ServiceIds.Length);
            foreach (var id in r.ServiceIds)
            {
                var s = catalog.TryGetValue(id, out var listed) ? listed : (await peers.Service(id, cancellationToken)).Service;
                services.Add(new ServiceRefView { Id = s.Id, Name = s.Name });
            }
            items.Add(new VerificationQueueItemView
            {
                ProviderId = r.ProviderId,
                Name = merchant.FullName,
                PendingItems = r.PendingItems,
                SubmittedAt = VerificationMappingProfile.Iso(r.SubmittedAt),
                AgeHours = (long)Math.Truncate((now - r.SubmittedAt).TotalHours),
                Services = services,
            });
        }
        return items;
    }

    /// <summary>Everything a verifier sees for one merchant; the NID is decrypted only here.</summary>
    public async Task<VerificationReviewView> Review(Guid id, CancellationToken cancellationToken)
    {
        var merchant = await peers.Merchant(id, cancellationToken);
        var st = await states.Load(id, cancellationToken);
        var nid = st.NidCiphertext is null ? null : Encoding.UTF8.GetString(cipher.Decrypt(st.NidCiphertext));
        var extra = ProfileFields(merchant);
        var items = ItemType.All.Select(t =>
        {
            var item = st.ItemOf(t);
            var view = mapper.Map<ItemState, VerificationItemView>(item);
            var fields = new Dictionary<string, string>(item.Fields);
            foreach (var (k, v) in extra.GetValueOrDefault(t, []))
            {
                fields[k] = v;
            }
            var documents = st.Documents.Where(d => d.ItemType == t).Select(d => new ReviewDocumentView { MediaId = d.MediaId, Kind = d.Kind }).ToList();
            return new ReviewItemView
            {
                Type = view.Type,
                Status = view.Status,
                Required = view.Required,
                RejectionReason = view.RejectionReason,
                DecidedAt = view.DecidedAt,
                ExpiresAt = view.ExpiresAt,
                Documents = documents,
                Fields = fields,
            };
        }).ToList();
        return new VerificationReviewView
        {
            ProviderId = merchant.Id,
            Level = st.Level,
            Profile = Profile(merchant, nid),
            FaceMatch = st.ItemOf(ItemType.Selfie).Status != ItemStatus.Missing ? "manual_review" : "not_run",
            Items = items,
        };
    }

    /// <summary>
    /// Approves or rejects one item; the decision and any level change are audited through
    /// their events (PRD §6.4). A rejection needs a reason of at least three characters.
    /// </summary>
    public async Task<VerificationReviewView> Decide(Guid providerId, string item, Guid actor, bool approve, string reason, CancellationToken cancellationToken)
    {
        reason = reason.Trim();
        if (!approve && reason.EnumerateRunes().Count() < 3)
        {
            throw new DomainException(VerificationReasons.Invalid);
        }
        var now = states.Now;
        await states.Change(providerId, "review", st =>
        {
            st.Items[item] = VerificationRules.Decided(st.ItemOf(item), new ItemDecision(now, actor, approve, reason));
            IDomainEvent decision = approve
                ? new DocumentApproved { ProviderId = providerId, Item = item, ActorId = actor }
                : new DocumentRejected { ProviderId = providerId, Item = item, Reason = reason, ActorId = actor };
            return [decision];
        }, cancellationToken);
        return await Review(providerId, cancellationToken);
    }

    // The profile data a verifier checks beside each profile item.
    private static Dictionary<string, Dictionary<string, string>> ProfileFields(MerchantProfile p)
    {
        var area = new Dictionary<string, string>
        {
            ["workingRadiusM"] = p.WorkingRadiusM.ToString(CultureInfo.InvariantCulture),
            ["services"] = p.ServiceIds.Count.ToString(CultureInfo.InvariantCulture),
        };
        if (p.HomeBase is { } home)
        {
            area["homeLat"] = home.Lat.ToString("F6", CultureInfo.InvariantCulture);
            area["homeLng"] = home.Lng.ToString("F6", CultureInfo.InvariantCulture);
        }
        var fields = new Dictionary<string, Dictionary<string, string>>
        {
            [ItemType.Address] = new() { ["presentAddress"] = p.PresentAddress, ["permanentAddress"] = p.PermanentAddress },
            [ItemType.ServiceArea] = area,
        };
        if (p.EmergencyContact is { } c)
        {
            fields[ItemType.EmergencyContact] = new() { ["name"] = c.Name, ["relation"] = c.Relation, ["phone"] = c.Phone };
        }
        return fields;
    }

    private static ReviewProfileView Profile(MerchantProfile p, string? nid) => new()
    {
        FullName = p.FullName,
        // Go wrote its zero date for a merchant who never saved the personal step.
        DateOfBirth = (p.DateOfBirth ?? DateOnly.MinValue).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
        Gender = p.Gender,
        Phone = p.Phone,
        PresentAddress = p.PresentAddress,
        PermanentAddress = p.PermanentAddress,
        NidNumber = nid,
    };
}
