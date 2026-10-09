import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

import 'support/fake_adapter.dart';

void main() {
  final request = UploadFile(bytes: Uint8List(10), purpose: 'nid_front');

  test('puts with the signed headers, retries, then confirms', () async {
    final storage = FakeAdapter()
      ..fail(DioExceptionType.connectionError)
      ..reply(200);
    final confirmed = <String>[];
    final progress = <double>[];
    final id = await MediaUploader(
      create: (r) async => SignedUpload(
        mediaId: 'm1',
        url: 'http://s3.test/put',
        headers: {'x-amz-meta': r.purpose},
      ),
      confirm: (id) async => confirmed.add(id),
      storage: fakeDio(storage),
    ).upload(request, onProgress: progress.add);
    expect(id, 'm1');
    expect(confirmed, ['m1']);
    expect(storage.requests.last.headers['x-amz-meta'], 'nid_front');
    expect(storage.requests.last.method, 'PUT');
    expect(progress, isNotEmpty);
  });

  test('gives up after the last attempt without confirming', () async {
    final storage = FakeAdapter();
    for (var i = 0; i < 2; i++) {
      storage.fail(DioExceptionType.connectionTimeout);
    }
    var confirmed = false;
    final uploader = MediaUploader(
      create: (_) async =>
          const SignedUpload(mediaId: 'm', url: 'http://s3.test'),
      confirm: (_) async => confirmed = true,
      storage: fakeDio(storage),
      attempts: 2,
    );
    await expectLater(uploader.upload(request), throwsA(isA<DioException>()));
    expect(confirmed, isFalse);
    expect(
      MediaUploader(
        create: uploader.create,
        confirm: uploader.confirm,
      ).attempts,
      3,
    );
  });
}
