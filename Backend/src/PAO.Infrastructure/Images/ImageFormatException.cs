namespace PAO.Infrastructure.Images;

/// <summary>Thrown when a file is not a well-formed image of the type it claims.</summary>
public sealed class ImageFormatException(string message, Exception? innerException = null) : Exception(message, innerException);
