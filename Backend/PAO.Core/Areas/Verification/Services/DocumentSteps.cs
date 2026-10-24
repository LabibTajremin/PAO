using System.Globalization;
using System.Text;
using PAO.Core.Areas.Verification.Repositories;
using PAO.Infrastructure.Crypto;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>One file of a document step.</summary>
public sealed record Upload(string Kind, Guid MediaId);

/// <summary>A document step as the merchant sends it; `Extra` makes further edits, e.g. the new NID.</summary>
public sealed record Submission(string Item, IReadOnlyList<Upload> Files, IReadOnlyDictionary<string, string> Fields, DateTimeOffset? ExpiresAt, Action<VerificationState>? Extra = null);

/// <summary>The document steps of the enrolment wizard (M08–M11).</summary>
public sealed class DocumentSteps(VerificationStates states, VerificationPeers peers, VerificationRepository repository, DataCipher cipher)
{
    /// <summary>
    /// Stores the encrypted NID number with both sides of the card (M08). A number on the
    /// block list cannot enrol again (PRD §6.4).
    /// </summary>
    public async Task<EnrolmentStatus> SaveNid(Guid id, NidInput input, CancellationToken cancellationToken)
    {
        if (!VerificationRules.ValidNid(input.NidNumber))
        {
            throw new DomainException(VerificationReasons.Invalid);
        }
        var hash = cipher.LookupHash(input.NidNumber);
        if (await repository.NidBlocked(hash, cancellationToken))
        {
            throw new DomainException(VerificationReasons.NidBlocked);
        }
        var ciphertext = cipher.Encrypt(Encoding.UTF8.GetBytes(input.NidNumber));
        Upload[] files = [new("nid_front", input.FrontMediaId), new("nid_back", input.BackMediaId)];
        return await Submit(id, new Submission(ItemType.Nid, files, Empty, null, st =>
        {
            st.NidCiphertext = ciphertext;
            st.NidHash = hash;
            st.NidChanged = true;
        }), cancellationToken);
    }

    /// <summary>Stores the live selfie (M09); a verifier compares it with the NID photo (D10).</summary>
    public Task<EnrolmentStatus> SaveSelfie(Guid id, Guid mediaId, CancellationToken cancellationToken) =>
        Submit(id, new Submission(ItemType.Selfie, [new("selfie", mediaId)], Empty, null), cancellationToken);

    /// <summary>
    /// Stores the certificate; it must be under the validity period old and expires that long
    /// after its issue date (PRD §6.2 item 4, §6.4).
    /// </summary>
    public async Task<EnrolmentStatus> SavePoliceClearance(Guid id, Guid mediaId, DateOnly issued, CancellationToken cancellationToken)
    {
        var settings = await peers.Settings(cancellationToken);
        // The issue date is a Dhaka calendar date, so "today" must be one too; UTC would
        // reject a certificate issued today for the six hours after 18:00 UTC.
        var today = DhakaDates.Today(states.Now);
        var expiresAt = VerificationRules.ClearanceExpiry(issued, today, settings.PoliceClearanceValidity)
            ?? throw new DomainException(VerificationReasons.ClearanceTooOld);
        var fields = new Dictionary<string, string> { ["issueDate"] = issued.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) };
        return await Submit(id, new Submission(ItemType.PoliceClearance, [new("police_clearance", mediaId)], fields, expiresAt), cancellationToken);
    }

    /// <summary>Stores optional certificates or work photos (PRD §6.2 item 7).</summary>
    public Task<EnrolmentStatus> SaveSkillProof(Guid id, IReadOnlyList<Guid> mediaIds, CancellationToken cancellationToken)
    {
        if (mediaIds.Count is 0 or > 10)
        {
            throw new DomainException(VerificationReasons.Invalid);
        }
        var files = mediaIds.Select(m => new Upload("skill_proof", m)).ToList();
        return Submit(id, new Submission(ItemType.SkillProof, files, Empty, null), cancellationToken);
    }

    private static Dictionary<string, string> Empty => [];

    /// <summary>Attaches the uploads, puts the item into review and marks the wizard step.</summary>
    private async Task<EnrolmentStatus> Submit(Guid id, Submission s, CancellationToken cancellationToken)
    {
        foreach (var f in s.Files)
        {
            await peers.Attach(id, f.MediaId, [f.Kind], cancellationToken);
        }
        var now = states.Now;
        await states.Change(id, "resubmitted", st =>
        {
            s.Extra?.Invoke(st);
            st.Items[s.Item] = VerificationRules.Submitted(st.ItemOf(s.Item), now, s.Fields, s.ExpiresAt);
            st.NewDocuments.AddRange(s.Files.Select(f => new VerificationDocument { Id = states.NewId(), ItemType = s.Item, Kind = f.Kind, MediaId = f.MediaId, CreatedAt = now }));
            return [];
        }, cancellationToken);
        return await peers.MarkStepDone(id, s.Item, cancellationToken);
    }
}
