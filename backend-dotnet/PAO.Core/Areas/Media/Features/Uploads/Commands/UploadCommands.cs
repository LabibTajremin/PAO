using FluentValidation;
using PAO.Core.Areas.Media.Services;
using PAO.Lib.Areas.Media;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Media.Features.Uploads.Commands;

/// <summary>Records a pending upload of `Owner` from an app and hands out a presigned PUT URL.</summary>
public sealed record CreateUpload(Guid Owner, Uploader Uploader, UploadInput File) : ICommand<UploadTicketView>;

/// <summary>Checks that the owner's file arrived with the declared type and size.</summary>
public sealed record ConfirmUpload(Guid Owner, Guid MediaId) : ICommand<MediaObjectView>;

/// <summary>
/// Refuses a file the purpose's rules forbid before the transaction opens, with the
/// domain reason (UPLOAD_INVALID), not a generic validation failure.
/// </summary>
public sealed class CreateUploadValidator : AbstractValidator<CreateUpload>
{
    /// <summary>Declares the rule.</summary>
    public CreateUploadValidator() => RuleFor(r => r).Custom((r, _) =>
    {
        if (MediaRules.Refusal(r.Uploader, r.File.Purpose, r.File.ContentType, r.File.SizeBytes) is { } refusal)
        {
            throw new DomainException(refusal);
        }
    });
}

/// <summary>Answers <see cref="CreateUpload"/>; the purpose's rules are checked before anything is stored.</summary>
public sealed class CreateUploadHandler(MediaFiles files, IMapper mapper) : IRequestHandler<CreateUpload, UploadTicketView>
{
    /// <inheritdoc />
    public async Task<UploadTicketView> Handle(CreateUpload request, CancellationToken cancellationToken) =>
        mapper.Map<UploadTicket, UploadTicketView>(await files.CreateUpload(request.Owner, request.Uploader, request.File, cancellationToken));
}

/// <summary>Answers <see cref="ConfirmUpload"/>.</summary>
public sealed class ConfirmUploadHandler(MediaFiles files, IMapper mapper) : IRequestHandler<ConfirmUpload, MediaObjectView>
{
    /// <inheritdoc />
    public async Task<MediaObjectView> Handle(ConfirmUpload request, CancellationToken cancellationToken) =>
        mapper.Map<StoredObject, MediaObjectView>(await files.Confirm(request.Owner, request.MediaId, cancellationToken));
}
