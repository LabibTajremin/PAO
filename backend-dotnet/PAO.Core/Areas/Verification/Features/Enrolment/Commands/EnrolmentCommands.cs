using PAO.Core.Areas.Verification.Services;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Verification.Features.Enrolment.Commands;

/// <summary>saveNid (M08): the encrypted NID number with both sides of the card.</summary>
public sealed record SaveNid(Guid Merchant, NidInput Input) : ICommand<EnrolmentStatusView>;

/// <summary>saveSelfie (M09).</summary>
public sealed record SaveSelfie(Guid Merchant, SelfieInput Input) : ICommand<EnrolmentStatusView>;

/// <summary>savePoliceClearance (M10).</summary>
public sealed record SavePoliceClearance(Guid Merchant, PoliceClearanceInput Input) : ICommand<EnrolmentStatusView>;

/// <summary>saveSkillProof (M11).</summary>
public sealed record SaveSkillProof(Guid Merchant, SkillProofInput Input) : ICommand<EnrolmentStatusView>;

/// <summary>submitEnrolment: sends the enrolment to the review queue.</summary>
public sealed record SubmitEnrolment(Guid Merchant) : ICommand<VerificationStatusView>;

/// <summary>Answers <see cref="SaveNid"/>.</summary>
public sealed class SaveNidHandler(DocumentSteps steps, IMapper mapper) : IRequestHandler<SaveNid, EnrolmentStatusView>
{
    /// <inheritdoc />
    public async Task<EnrolmentStatusView> Handle(SaveNid request, CancellationToken cancellationToken) =>
        mapper.Map<EnrolmentStatus, EnrolmentStatusView>(await steps.SaveNid(request.Merchant, request.Input, cancellationToken));
}

/// <summary>Answers <see cref="SaveSelfie"/>.</summary>
public sealed class SaveSelfieHandler(DocumentSteps steps, IMapper mapper) : IRequestHandler<SaveSelfie, EnrolmentStatusView>
{
    /// <inheritdoc />
    public async Task<EnrolmentStatusView> Handle(SaveSelfie request, CancellationToken cancellationToken) =>
        mapper.Map<EnrolmentStatus, EnrolmentStatusView>(await steps.SaveSelfie(request.Merchant, request.Input.MediaId, cancellationToken));
}

/// <summary>Answers <see cref="SavePoliceClearance"/>.</summary>
public sealed class SavePoliceClearanceHandler(DocumentSteps steps, IMapper mapper) : IRequestHandler<SavePoliceClearance, EnrolmentStatusView>
{
    /// <inheritdoc />
    public async Task<EnrolmentStatusView> Handle(SavePoliceClearance request, CancellationToken cancellationToken) =>
        mapper.Map<EnrolmentStatus, EnrolmentStatusView>(
            await steps.SavePoliceClearance(request.Merchant, request.Input.MediaId, request.Input.IssueDate, cancellationToken));
}

/// <summary>Answers <see cref="SaveSkillProof"/>.</summary>
public sealed class SaveSkillProofHandler(DocumentSteps steps, IMapper mapper) : IRequestHandler<SaveSkillProof, EnrolmentStatusView>
{
    /// <inheritdoc />
    public async Task<EnrolmentStatusView> Handle(SaveSkillProof request, CancellationToken cancellationToken) =>
        mapper.Map<EnrolmentStatus, EnrolmentStatusView>(await steps.SaveSkillProof(request.Merchant, request.Input.MediaIds, cancellationToken));
}

/// <summary>Answers <see cref="SubmitEnrolment"/>.</summary>
public sealed class SubmitEnrolmentHandler(MerchantStatus status) : IRequestHandler<SubmitEnrolment, VerificationStatusView>
{
    /// <inheritdoc />
    public Task<VerificationStatusView> Handle(SubmitEnrolment request, CancellationToken cancellationToken) =>
        status.Submit(request.Merchant, cancellationToken);
}
