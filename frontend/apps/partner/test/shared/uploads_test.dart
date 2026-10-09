import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/shared/uploads.dart';

import '../support/harness.dart';

void main() {
  test('creates a ticket, puts the file and confirms it', () async {
    final h = await Harness.create();
    final storage = Dio();
    DioAdapter(dio: storage).onPut(
      'http://s3.test/obj',
      (s) => s.reply(200, null),
      data: Matchers.any,
    );
    h.http
      ..onPost(
        '/v1/provider/uploads',
        (s) => s.reply(201, {
          'mediaId': '11111111-1111-1111-1111-111111111111',
          'uploadUrl': 'http://s3.test/obj',
          'headers': {'Content-Type': 'image/jpeg'},
          'expiresAt': '2026-10-09T10:00:00Z',
        }),
        data: {
          'purpose': 'selfie',
          'contentType': 'image/jpeg',
          'sizeBytes': 4,
        },
      )
      ..onPost(
        '/v1/provider/uploads/11111111-1111-1111-1111-111111111111/confirm',
        (s) => s.reply(200, {
          'id': '11111111-1111-1111-1111-111111111111',
          'purpose': 'selfie',
          'contentType': 'image/jpeg',
          'sizeBytes': 4,
          'status': 'confirmed',
        }),
      );
    final id = await providerUploader(
      h.services.api,
      storage: storage,
    ).upload(UploadFile(bytes: Uint8List(4), purpose: 'selfie'));
    expect(id, '11111111-1111-1111-1111-111111111111');
    expect(h.bodyOf('/v1/provider/uploads'), {
      'purpose': 'selfie',
      'contentType': 'image/jpeg',
      'sizeBytes': 4,
    });
  });
}
