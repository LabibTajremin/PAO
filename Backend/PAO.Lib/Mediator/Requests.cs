namespace PAO.Lib.Mediator;

/// <summary>A request the mediator dispatches to exactly one handler.</summary>
public interface IRequest<TResult>
{
}

/// <summary>A use case that changes state; it runs inside a database transaction.</summary>
public interface ICommand<TResult> : IRequest<TResult>
{
}

/// <summary>A use case that changes state and answers nothing.</summary>
public interface ICommand : ICommand<Unit>
{
}

/// <summary>A use case that only reads; it never opens a transaction.</summary>
public interface IQuery<TResult> : IRequest<TResult>
{
}

/// <summary>Handles one request type; one handler per use case.</summary>
public interface IRequestHandler<in TRequest, TResult>
    where TRequest : IRequest<TResult>
{
    /// <summary>Runs the use case.</summary>
    Task<TResult> Handle(TRequest request, CancellationToken cancellationToken);
}

/// <summary>Continues the pipeline with the next behaviour or the handler.</summary>
public delegate Task<TResult> RequestHandlerDelegate<TResult>();

/// <summary>
/// Wraps every request on its way to the handler (validation, logging, transactions), in
/// registration order.
/// </summary>
public interface IPipelineBehavior<in TRequest, TResult>
    where TRequest : IRequest<TResult>
{
    /// <summary>Does this behaviour's part and calls `next` to continue.</summary>
    Task<TResult> Handle(TRequest request, RequestHandlerDelegate<TResult> next, CancellationToken cancellationToken);
}

/// <summary>Sends requests to their handlers; controllers depend on nothing else.</summary>
public interface IMediator
{
    /// <summary>Runs `request` through the pipeline and its handler.</summary>
    Task<TResult> Send<TResult>(IRequest<TResult> request, CancellationToken cancellationToken = default);
}

/// <summary>The result of a command that answers nothing.</summary>
public sealed class Unit
{
    private Unit()
    {
    }

    /// <summary>The only value.</summary>
    public static Unit Value { get; } = new();
}
