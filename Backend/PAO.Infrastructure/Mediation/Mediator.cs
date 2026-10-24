using System.Collections.Concurrent;
using Microsoft.Extensions.DependencyInjection;
using PAO.Lib.Mediator;
using PAO.Lib.Validation;

namespace PAO.Infrastructure.Mediation;

/// <summary>
/// The in-house mediator (MediatR's licence is commercial, ADR-0034): resolves the one
/// handler for a request from the scope and runs it inside the registered behaviours,
/// first registered outermost.
/// </summary>
public sealed class Mediator(IServiceProvider services) : IMediator
{
    private static readonly ConcurrentDictionary<Type, object> Dispatchers = new();

    // FluentValidation fixes a rule's property name when the validator is built, from the
    // global resolvers. Validators are resolved after the mediator, so configuring them here
    // keeps 422 field names in JSON case however the container was assembled.
    static Mediator() => ValidationSetup.Configure();

    /// <inheritdoc />
    public Task<TResult> Send<TResult>(IRequest<TResult> request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);
        var dispatcher = (Dispatcher<TResult>)Dispatchers.GetOrAdd(
            request.GetType(),
            type => Activator.CreateInstance(typeof(Dispatcher<,>).MakeGenericType(type, typeof(TResult)))!);
        return dispatcher.Send(services, request, cancellationToken);
    }

    private abstract class Dispatcher<TResult>
    {
        public abstract Task<TResult> Send(IServiceProvider services, IRequest<TResult> request, CancellationToken cancellationToken);
    }

    private sealed class Dispatcher<TRequest, TResult> : Dispatcher<TResult>
        where TRequest : IRequest<TResult>
    {
        public override Task<TResult> Send(IServiceProvider services, IRequest<TResult> request, CancellationToken cancellationToken)
        {
            var typed = (TRequest)request;
            var handler = services.GetService<IRequestHandler<TRequest, TResult>>()
                ?? throw new InvalidOperationException($"no handler registered for {typeof(TRequest).Name}");
            RequestHandlerDelegate<TResult> pipeline = () => handler.Handle(typed, cancellationToken);
            foreach (var behavior in services.GetServices<IPipelineBehavior<TRequest, TResult>>().Reverse())
            {
                var next = pipeline;
                pipeline = () => behavior.Handle(typed, next, cancellationToken);
            }
            return pipeline();
        }
    }
}
