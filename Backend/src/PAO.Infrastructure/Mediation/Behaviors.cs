using System.Diagnostics;
using FluentValidation;
using Microsoft.Extensions.Logging;
using PAO.EF;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Mediator;

namespace PAO.Infrastructure.Mediation;

/// <summary>Logs each request's name and duration at debug level, and failures as warnings.</summary>
public sealed class LoggingBehavior<TRequest, TResult>(ILogger<LoggingBehavior<TRequest, TResult>> logger) : IPipelineBehavior<TRequest, TResult>
    where TRequest : IRequest<TResult>
{
    /// <inheritdoc />
    public async Task<TResult> Handle(TRequest request, RequestHandlerDelegate<TResult> next, CancellationToken cancellationToken)
    {
        var started = Stopwatch.GetTimestamp();
        try
        {
            var result = await next();
            logger.LogDebug("handled {Request} in {Ms} ms", typeof(TRequest).Name, Stopwatch.GetElapsedTime(started).TotalMilliseconds);
            return result;
        }
        catch (Exception error)
        {
            logger.LogWarning("{Request} failed after {Ms} ms: {Error}", typeof(TRequest).Name, Stopwatch.GetElapsedTime(started).TotalMilliseconds, error.Message);
            throw;
        }
    }
}

/// <summary>
/// Runs the request's FluentValidation validators; the first failure becomes 422
/// VALIDATION_FAILED with the field and reason, the shape the spec validation uses.
/// </summary>
public sealed class ValidationBehavior<TRequest, TResult>(IEnumerable<IValidator<TRequest>> validators) : IPipelineBehavior<TRequest, TResult>
    where TRequest : IRequest<TResult>
{
    /// <inheritdoc />
    public async Task<TResult> Handle(TRequest request, RequestHandlerDelegate<TResult> next, CancellationToken cancellationToken)
    {
        foreach (var validator in validators)
        {
            var result = await validator.ValidateAsync(request, cancellationToken);
            if (result.Errors.FirstOrDefault() is { } failure)
            {
                throw ApiErrors.ValidationFailed.WithDetails(new Dictionary<string, object?>
                {
                    ["field"] = failure.PropertyName,
                    ["reason"] = failure.ErrorMessage,
                });
            }
        }
        return await next();
    }
}

/// <summary>
/// Runs commands inside a database transaction on the scope's context, committing when the
/// handler returns and rolling back when it throws. A command sent from inside another
/// joins the open transaction. Queries never open one.
/// </summary>
public sealed class TransactionBehavior<TRequest, TResult>(PaoDbContext db) : IPipelineBehavior<TRequest, TResult>
    where TRequest : IRequest<TResult>
{
    /// <inheritdoc />
    public async Task<TResult> Handle(TRequest request, RequestHandlerDelegate<TResult> next, CancellationToken cancellationToken)
    {
        if (request is not ICommand<TResult> || db.Database.CurrentTransaction is not null)
        {
            return await next();
        }
        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        var result = await next();
        await transaction.CommitAsync(cancellationToken);
        return result;
    }
}
