import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Where and how to PUT a file, from the API's create-upload call.
class SignedUpload {
  /// Creates a ticket.
  const SignedUpload({
    required this.mediaId,
    required this.url,
    this.headers = const {},
  });

  /// ID to confirm and attach.
  final String mediaId;

  /// Signed URL.
  final String url;

  /// Headers the signature covers.
  final Map<String, String> headers;
}

/// What to upload.
class UploadFile {
  /// Creates a request.
  const UploadFile({
    required this.bytes,
    required this.purpose,
    this.contentType = 'image/jpeg',
  });

  /// File content.
  final Uint8List bytes;

  /// Media purpose, e.g. `nid_front`.
  final String purpose;

  /// MIME type.
  final String contentType;
}

/// Uploads straight to object storage with a signed URL, retrying the PUT on a
/// flaky link, then confirms it with the API (PRD §9.4).
class MediaUploader {
  /// Creates the uploader; [storage] sends the PUT (a bare client).
  MediaUploader({
    required this.create,
    required this.confirm,
    Dio? storage,
    this.attempts = 3,
  }) : _storage = storage ?? Dio();

  /// Asks the API for a ticket.
  final Future<SignedUpload> Function(UploadFile request) create;

  /// Tells the API the file is in place.
  final Future<void> Function(String mediaId) confirm;

  /// PUT attempts before giving up.
  final int attempts;

  final Dio _storage;

  /// Uploads and returns the media ID; [onProgress] gets 0–1.
  Future<String> upload(
    UploadFile request, {
    void Function(double progress)? onProgress,
  }) async {
    final ticket = await create(request);
    for (var attempt = 1; ; attempt++) {
      try {
        await _storage.put<void>(
          ticket.url,
          data: Stream.value(request.bytes),
          options: Options(
            headers: {
              ...ticket.headers,
              Headers.contentLengthHeader: request.bytes.length,
            },
          ),
          onSendProgress: (sent, total) =>
              onProgress?.call(total <= 0 ? 0 : sent / total),
        );
        break;
      } on DioException {
        if (attempt >= attempts) rethrow;
      }
    }
    await confirm(ticket.mediaId);
    return ticket.mediaId;
  }
}
