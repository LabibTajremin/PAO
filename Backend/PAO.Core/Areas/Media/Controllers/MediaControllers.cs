using Microsoft.AspNetCore.Mvc;
using PAO.Core.Areas.Media.Features.Documents.Queries;
using PAO.Core.Areas.Media.Features.Uploads.Commands;
using PAO.Core.Areas.Media.Services;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Media;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Media.Controllers;

/// <summary>Media failures as API errors, with the codes and messages existing clients rely on.</summary>
public sealed class MediaErrorMap : IErrorMap
{
    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [MediaReasons.Invalid] = new(422, "UPLOAD_INVALID", "This file type or size is not allowed here."),
        [MediaReasons.Forbidden] = new(422, "UPLOAD_INVALID", "This app cannot upload that kind of file."),
        [MediaErrors.NotFound] = ApiErrors.NotFound,
        [MediaErrors.NotUploaded] = new(409, "UPLOAD_NOT_FOUND", "The file did not arrive or does not match. Upload it again."),
    };
}

/// <summary>Customer uploads: avatars and complaint photos.</summary>
[ApiController]
[Area("Media")]
[Route("v1/customer/uploads")]
[ErrorMap(typeof(MediaErrorMap))]
[AllUserType(Permission = "media:upload")]
public sealed class CustomerUploadsController(IMediator mediator) : ControllerBase
{
    /// <summary>createCustomerUpload.</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] UploadInput body) =>
        StatusCode(201, await mediator.Send(new CreateUpload(HttpContext.Caller().AccountId, Uploader.Customer, body), HttpContext.RequestAborted));

    /// <summary>confirmCustomerUpload.</summary>
    [HttpPost("{mediaId}/confirm")]
    public Task<MediaObjectView> Confirm(Guid mediaId) =>
        mediator.Send(new ConfirmUpload(HttpContext.Caller().AccountId, mediaId), HttpContext.RequestAborted);
}

/// <summary>Partner uploads, verification documents included.</summary>
[ApiController]
[Area("Media")]
[Route("v1/provider/uploads")]
[ErrorMap(typeof(MediaErrorMap))]
[AllUserType(Permission = "media:upload")]
public sealed class MerchantUploadsController(IMediator mediator) : ControllerBase
{
    /// <summary>createProviderUpload.</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] UploadInput body) =>
        StatusCode(201, await mediator.Send(new CreateUpload(HttpContext.Caller().AccountId, Uploader.Merchant, body), HttpContext.RequestAborted));

    /// <summary>confirmProviderUpload.</summary>
    [HttpPost("{mediaId}/confirm")]
    public Task<MediaObjectView> Confirm(Guid mediaId) =>
        mediator.Send(new ConfirmUpload(HttpContext.Caller().AccountId, mediaId), HttpContext.RequestAborted);
}

/// <summary>The admin document viewer; each view of a verification document is audited.</summary>
[ApiController]
[Area("Media")]
[Route("v1/admin/documents")]
[ErrorMap(typeof(MediaErrorMap))]
public sealed class DocumentsController(IMediator mediator) : ControllerBase
{
    /// <summary>getDocumentViewURL.</summary>
    [HttpGet("{mediaId}/view-url")]
    [Admin(Permission = "verification:docs:view")]
    public Task<ViewUrlView> ViewUrl(Guid mediaId)
    {
        var me = HttpContext.Caller();
        return mediator.Send(new GetDocumentViewUrl(mediaId, me.AccountId, me.Roles.FirstOrDefault() ?? string.Empty), HttpContext.RequestAborted);
    }
}
