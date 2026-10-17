import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/shared/uploads.dart';

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
    const id = '11111111-1111-1111-1111-111111111111';
    h.http
      ..onPost(
        '/v1/customer/uploads',
        (s) => s.reply(201, {
          'mediaId': id,
          'uploadUrl': 'http://s3.test/obj',
          'headers': {'Content-Type': 'image/jpeg'},
          'expiresAt': '2026-10-09T10:00:00Z',
        }),
      )
      ..onPost(
        '/v1/customer/uploads/$id/confirm',
        (s) => s.reply(200, {
          'id': id,
          'purpose': 'complaint_photo',
          'contentType': 'image/jpeg',
          'sizeBytes': 4,
          'status': 'confirmed',
        }),
      );
    final got = await customerUploader(
      h.services.api,
      storage: storage,
    ).upload(UploadFile(bytes: Uint8List(4), purpose: 'complaint_photo'));
    expect(got, id);
    expect(h.bodyOf('/v1/customer/uploads'), {
      'purpose': 'complaint_photo',
      'contentType': 'image/jpeg',
      'sizeBytes': 4,
    });
  });
}
