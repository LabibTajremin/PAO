using PAO.EF.Billing;
using PAO.Lib.Areas.Billing;

namespace PAO.Core.Areas.Billing.Services;

/// <summary>The event every step of a payment submission publishes.</summary>
public static class PaymentSteps
{
    /// <summary>`step` filled from the submission, with the due after the step and who acted.</summary>
    public static T Event<T>(T step, PaymentSubmissionRecord s, DueWithLimits due, Guid actorId)
        where T : PaymentEvent => step with
        {
            SubmissionId = s.Id,
            ProviderId = s.ProviderId,
            AmountPaisa = s.AmountPaisa,
            Method = s.Method,
            DuePaisa = due.Totals.DuePaisa,
            Reason = s.Reason,
            ActorId = actorId,
        };
}
