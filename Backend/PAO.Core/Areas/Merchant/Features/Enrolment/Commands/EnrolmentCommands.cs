using PAO.Core.Areas.Merchant.Services;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Merchant.Features.Enrolment.Commands;

/// <summary>Saves the personal step (M05); the merchant must be 18 in Dhaka today.</summary>
public sealed record SavePersonalStep(Guid MerchantId, PersonalInfoInput Input) : ICommand<EnrolmentStatus>;

/// <summary>Saves the services step (M06) and takes the merchant offline.</summary>
public sealed record SaveServicesStep(Guid MerchantId, ServicesInput Input) : ICommand<EnrolmentStatus>;

/// <summary>Saves the service-area step (M07).</summary>
public sealed record SaveAreaStep(Guid MerchantId, ServiceAreaInput Input) : ICommand<EnrolmentStatus>;

/// <summary>Stores the emergency contact and sends them a code (M12).</summary>
public sealed record SaveEmergencyContactStep(Guid MerchantId, EmergencyContactInput Input) : ICommand<EnrolmentStatus>;

/// <summary>Checks the code the emergency contact received.</summary>
public sealed record VerifyEmergencyContact(Guid MerchantId, string Code) : ICommand<EnrolmentStatus>;

/// <summary>Records the accepted code of conduct (M13).</summary>
public sealed record SaveCodeOfConductStep(Guid MerchantId, CodeOfConductInput Input) : ICommand<EnrolmentStatus>;

/// <summary>Answers <see cref="SavePersonalStep"/>.</summary>
public sealed class SavePersonalStepHandler(MerchantEnrolment enrolment) : IRequestHandler<SavePersonalStep, EnrolmentStatus>
{
    /// <inheritdoc />
    public Task<EnrolmentStatus> Handle(SavePersonalStep request, CancellationToken cancellationToken) =>
        enrolment.SavePersonal(request.MerchantId, request.Input, cancellationToken);
}

/// <summary>Answers <see cref="SaveServicesStep"/>.</summary>
public sealed class SaveServicesStepHandler(MerchantEnrolment enrolment) : IRequestHandler<SaveServicesStep, EnrolmentStatus>
{
    /// <inheritdoc />
    public Task<EnrolmentStatus> Handle(SaveServicesStep request, CancellationToken cancellationToken) =>
        enrolment.SaveServices(request.MerchantId, request.Input, cancellationToken);
}

/// <summary>Answers <see cref="SaveAreaStep"/>.</summary>
public sealed class SaveAreaStepHandler(MerchantEnrolment enrolment) : IRequestHandler<SaveAreaStep, EnrolmentStatus>
{
    /// <inheritdoc />
    public Task<EnrolmentStatus> Handle(SaveAreaStep request, CancellationToken cancellationToken) =>
        enrolment.SaveArea(request.MerchantId, request.Input, cancellationToken);
}

/// <summary>Answers <see cref="SaveEmergencyContactStep"/>; a failed send rolls the contact back.</summary>
public sealed class SaveEmergencyContactStepHandler(MerchantEnrolment enrolment) : IRequestHandler<SaveEmergencyContactStep, EnrolmentStatus>
{
    /// <inheritdoc />
    public Task<EnrolmentStatus> Handle(SaveEmergencyContactStep request, CancellationToken cancellationToken) =>
        enrolment.SaveContact(request.MerchantId, request.Input, cancellationToken);
}

/// <summary>Answers <see cref="VerifyEmergencyContact"/>.</summary>
public sealed class VerifyEmergencyContactHandler(MerchantEnrolment enrolment) : IRequestHandler<VerifyEmergencyContact, EnrolmentStatus>
{
    /// <inheritdoc />
    public Task<EnrolmentStatus> Handle(VerifyEmergencyContact request, CancellationToken cancellationToken) =>
        enrolment.VerifyContact(request.MerchantId, request.Code, cancellationToken);
}

/// <summary>Answers <see cref="SaveCodeOfConductStep"/>.</summary>
public sealed class SaveCodeOfConductStepHandler(MerchantEnrolment enrolment) : IRequestHandler<SaveCodeOfConductStep, EnrolmentStatus>
{
    /// <inheritdoc />
    public Task<EnrolmentStatus> Handle(SaveCodeOfConductStep request, CancellationToken cancellationToken) =>
        enrolment.AcceptCodeOfConduct(request.MerchantId, request.Input, cancellationToken);
}
