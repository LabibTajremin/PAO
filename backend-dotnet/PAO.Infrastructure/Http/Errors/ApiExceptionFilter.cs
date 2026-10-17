using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;

namespace PAO.Infrastructure.Http.Errors;

/// <summary>
/// The one place exceptions from the edge filters and controllers become HTTP answers: the
/// area's error map first, then the PRD §9.6 envelope.
/// </summary>
public sealed class ApiExceptionFilter(ILogger<ApiExceptionFilter> logger) : IAsyncExceptionFilter
{
    /// <inheritdoc />
    public async Task OnExceptionAsync(ExceptionContext context)
    {
        var error = context.Exception;
        if (context.ActionDescriptor is ControllerActionDescriptor action)
        {
            var map = action.MethodInfo.GetCustomAttribute<ErrorMapAttribute>()
                ?? action.ControllerTypeInfo.GetCustomAttribute<ErrorMapAttribute>();
            error = map?.Apply(error) ?? error;
        }
        await ErrorResponses.Write(context.HttpContext, error, logger);
        context.Result = new EmptyResult();
        context.ExceptionHandled = true;
    }
}
