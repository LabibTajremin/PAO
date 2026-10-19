using PAO.Core.Areas.Merchant.Repositories;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>The resumable enrolment wizard (M05–M13): the profile steps and submission.</summary>
public sealed class MerchantEnrolment(MerchantProfiles profiles, MerchantRepository repository, MerchantPeers peers, IPresence presence)
{
    /// <summary>The wizard progress; nothing saved yet means every step is open.</summary>
    public async Task<EnrolmentStatus> Progress(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            return EnrolmentRules.ProgressOf(await repository.Get(id, cancellationToken));
        }
        catch (DomainException error) when (error.Reason == MerchantErrors.NotFound)
        {
            return EnrolmentRules.Progress([]);
        }
    }

    /// <summary>Saves the personal step; birthdays are Dhaka calendar dates (04-decisions E8), so today is one too.</summary>
    public Task<EnrolmentStatus> SavePersonal(Guid id, PersonalInfoInput input, CancellationToken cancellationToken)
    {
        if (EnrolmentRules.PersonalProblem(input, EnrolmentRules.DhakaDate(profiles.Clock.Now)) is { } problem)
        {
            throw new DomainException(problem);
        }
        return profiles.Update(id, EnrolmentStep.Personal, m => m with
        {
            FullName = input.FullName.Trim(),
            DateOfBirth = input.DateOfBirth,
            Gender = input.Gender,
            PresentAddress = input.PresentAddress,
            PermanentAddress = input.PermanentAddress,
            Bio = input.Bio ?? string.Empty,
        }, cancellationToken);
    }

    /// <summary>
    /// Saves the services step. Changing services takes the merchant offline, so the
    /// presence index never lists them under a service they dropped.
    /// </summary>
    public async Task<EnrolmentStatus> SaveServices(Guid id, ServicesInput input, CancellationToken cancellationToken)
    {
        if (!EnrolmentRules.ServicesValid(input.ServiceIds.Count, input.ExperienceYears))
        {
            throw new DomainException(MerchantReasons.Invalid);
        }
        if ((await peers.Services(input.ServiceIds, cancellationToken)).Any(s => !s.Published))
        {
            throw new DomainException(MerchantReasons.UnknownService);
        }
        return await profiles.Update(id, EnrolmentStep.Services, async m =>
        {
            await presence.Offline(id, m.ServiceIds);
            return m with { ServiceIds = input.ServiceIds, ExperienceYears = input.ExperienceYears };
        }, cancellationToken);
    }

    /// <summary>Saves the area step.</summary>
    public Task<EnrolmentStatus> SaveArea(Guid id, ServiceAreaInput input, CancellationToken cancellationToken)
    {
        if (!EnrolmentRules.AreaValid(input.HomeBase, input.WorkingRadiusM))
        {
            throw new DomainException(MerchantReasons.Invalid);
        }
        return profiles.Update(id, EnrolmentStep.Area, m => m with { HomeBase = input.HomeBase, WorkingRadiusM = input.WorkingRadiusM }, cancellationToken);
    }

    /// <summary>Records the accepted version with a timestamp (PRD §6.2 item 9).</summary>
    public Task<EnrolmentStatus> AcceptCodeOfConduct(Guid id, CodeOfConductInput input, CancellationToken cancellationToken)
    {
        if (!input.Accepted || input.Version.Trim().Length == 0)
        {
            throw new DomainException(MerchantReasons.Invalid);
        }
        return profiles.Update(id, EnrolmentStep.CodeOfConduct, m => m with { CocVersion = input.Version, CocAcceptedAt = profiles.Clock.Now }, cancellationToken);
    }

    /// <summary>
    /// Stores the guarantor and sends them a code; the step is done only after
    /// <see cref="VerifyContact"/>. A failed send leaves the old contact in place.
    /// </summary>
    public Task<EnrolmentStatus> SaveContact(Guid id, EmergencyContactInput input, CancellationToken cancellationToken)
    {
        var phone = PhoneNumber.Normalize(input.Phone) ?? throw new DomainException(MerchantReasons.Invalid);
        var contact = new EmergencyContact { Name = input.Name, Relation = input.Relation, Phone = phone };
        return profiles.Update(id, null, async m =>
        {
            if (!EnrolmentRules.ContactValid(contact, m.Phone))
            {
                throw new DomainException(MerchantReasons.Invalid);
            }
            await peers.SendContactCode(phone, cancellationToken);
            return m with { Emergency = contact, StepsDone = EnrolmentRules.WithoutStep(m.StepsDone, EnrolmentStep.EmergencyContact) };
        }, cancellationToken);
    }

    /// <summary>Checks the code sent to the guarantor.</summary>
    public Task<EnrolmentStatus> VerifyContact(Guid id, string code, CancellationToken cancellationToken) =>
        profiles.Update(id, EnrolmentStep.EmergencyContact, async m =>
        {
            if (m.Emergency.Phone.Length == 0)
            {
                throw new DomainException(MerchantReasons.ContactUnproven);
            }
            await peers.CheckContactCode(m.Emergency.Phone, code, cancellationToken);
            return m with { Emergency = m.Emergency with { VerifiedAt = profiles.Clock.Now } };
        }, cancellationToken);

    /// <summary>Records a document step saved by Verification.</summary>
    public Task<EnrolmentStatus> MarkStepDone(Guid id, string step, CancellationToken cancellationToken) =>
        profiles.Update(id, step, m => m, cancellationToken);

    /// <summary>Records that the enrolment went to review; every required step must be done.</summary>
    public async Task MarkSubmitted(Guid id, CancellationToken cancellationToken)
    {
        var m = await profiles.Load(id, cancellationToken);
        if (!EnrolmentRules.ProgressOf(m).Complete)
        {
            throw new DomainException(MerchantErrors.EnrolmentIncomplete);
        }
        await repository.Save(m with { SubmittedAt = profiles.Clock.Now }, null, cancellationToken);
    }
}
