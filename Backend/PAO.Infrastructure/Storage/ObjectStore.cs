using System.Net;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using PAO.Infrastructure.Configuration;

namespace PAO.Infrastructure.Storage;

/// <summary>Thrown when an object does not exist.</summary>
public sealed class ObjectNotFoundException(string bucket, string key) : Exception($"object not found: {bucket}/{key}");

/// <summary>An object's stored metadata.</summary>
public sealed record ObjectInfo(long Size, string ContentType);

/// <summary>A presigned upload: the URL and the headers the client must send with the PUT.</summary>
public sealed record PresignedUpload(string Url, IReadOnlyDictionary<string, string> Headers);

/// <summary>
/// S3-compatible object storage (RustFS locally, any S3 in production): presigned uploads
/// and downloads, metadata checks and deletes (PRD §6.6). Buckets are private; clients only
/// get short-lived URLs, signed for the endpoint devices reach.
/// </summary>
public sealed class ObjectStore : IDisposable
{
    private readonly AmazonS3Client client;
    private readonly AmazonS3Client presigner;

    /// <summary>Connects to the configured endpoint; presigns for the public one.</summary>
    public ObjectStore(StorageOptions options)
    {
        client = Build(options, options.Endpoint);
        presigner = Build(options, string.IsNullOrEmpty(options.PublicEndpoint) ? options.Endpoint : options.PublicEndpoint);
    }

    /// <summary>
    /// A URL accepting one PUT of `contentType` until `ttl` passes; with `size`, the length
    /// is signed too, so storage refuses a file of any other size.
    /// </summary>
    public async Task<PresignedUpload> PresignPut(string bucket, string key, string contentType, TimeSpan ttl, long? size = null)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = bucket,
            Key = key,
            Verb = HttpVerb.PUT,
            ContentType = contentType,
            Expires = DateTime.UtcNow + ttl,
            Protocol = ProtocolOf(presigner),
        };
        if (size is { } length)
        {
            request.Headers.ContentLength = length;
        }
        var url = await presigner.GetPreSignedURLAsync(request);
        return new PresignedUpload(url, new Dictionary<string, string> { ["Content-Type"] = contentType });
    }

    /// <summary>A URL that downloads the object until `ttl` passes (5 minutes for documents).</summary>
    public Task<string> PresignGet(string bucket, string key, TimeSpan ttl)
    {
        return presigner.GetPreSignedURLAsync(new GetPreSignedUrlRequest
        {
            BucketName = bucket,
            Key = key,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow + ttl,
            Protocol = ProtocolOf(presigner),
        });
    }

    /// <summary>Returns the object's metadata or throws <see cref="ObjectNotFoundException"/>.</summary>
    public async Task<ObjectInfo> Head(string bucket, string key, CancellationToken cancellationToken)
    {
        try
        {
            var meta = await client.GetObjectMetadataAsync(bucket, key, cancellationToken);
            return new ObjectInfo(meta.ContentLength, meta.Headers.ContentType ?? string.Empty);
        }
        catch (AmazonS3Exception error) when (error.StatusCode == HttpStatusCode.NotFound)
        {
            throw new ObjectNotFoundException(bucket, key);
        }
    }

    /// <summary>Stores `content` under `key`; used by seeding and tests.</summary>
    public Task Put(string bucket, string key, string contentType, Stream content, CancellationToken cancellationToken) =>
        client.PutObjectAsync(new PutObjectRequest { BucketName = bucket, Key = key, ContentType = contentType, InputStream = content }, cancellationToken);

    /// <summary>Removes an object; deleting a missing object succeeds.</summary>
    public Task Delete(string bucket, string key, CancellationToken cancellationToken) =>
        client.DeleteObjectAsync(bucket, key, cancellationToken);

    /// <summary>
    /// Creates the bucket when missing and asks for default AES-256 server-side encryption,
    /// so documents are encrypted at rest (PRD §6.6).
    /// </summary>
    public async Task EnsureBucket(string bucket, CancellationToken cancellationToken)
    {
        if (!await Amazon.S3.Util.AmazonS3Util.DoesS3BucketExistV2Async(client, bucket))
        {
            await client.PutBucketAsync(new PutBucketRequest { BucketName = bucket }, cancellationToken);
        }
        await client.PutBucketEncryptionAsync(new PutBucketEncryptionRequest
        {
            BucketName = bucket,
            ServerSideEncryptionConfiguration = new ServerSideEncryptionConfiguration
            {
                ServerSideEncryptionRules = [new ServerSideEncryptionRule { ServerSideEncryptionByDefault = new ServerSideEncryptionByDefault { ServerSideEncryptionAlgorithm = ServerSideEncryptionMethod.AES256 } }],
            },
        }, cancellationToken);
    }

    /// <summary>Checks that storage answers and the bucket exists, for readiness.</summary>
    public Task Ping(string bucket, CancellationToken cancellationToken) =>
        client.GetBucketLocationAsync(new GetBucketLocationRequest { BucketName = bucket }, cancellationToken);

    /// <summary>Closes the HTTP connections.</summary>
    public void Dispose()
    {
        client.Dispose();
        presigner.Dispose();
    }

    private static AmazonS3Client Build(StorageOptions options, string endpoint) => new(
        new BasicAWSCredentials(options.AccessKey, options.SecretKey),
        new AmazonS3Config
        {
            ServiceURL = endpoint,
            ForcePathStyle = true,
            AuthenticationRegion = options.Region,
            // Presigned uploads come from phones that cannot add SDK checksum headers.
            RequestChecksumCalculation = RequestChecksumCalculation.WHEN_REQUIRED,
            ResponseChecksumValidation = ResponseChecksumValidation.WHEN_REQUIRED,
        });

    private static Protocol ProtocolOf(AmazonS3Client s3) =>
        s3.Config.ServiceURL.StartsWith("https:", StringComparison.OrdinalIgnoreCase) ? Protocol.HTTPS : Protocol.HTTP;
}
