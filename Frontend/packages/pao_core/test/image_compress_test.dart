import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pao_core/pao_core.dart';

void main() {
  test(
    'large photos shrink to the longest side, small ones keep their size',
    () {
      final big = img.encodePng(img.Image(width: 400, height: 200));
      final out = img.decodeJpg(compressPhoto(big, maxSide: 100)!)!;
      expect([out.width, out.height], [100, 50]);
      final small = img.decodeJpg(compressPhoto(big)!)!;
      expect(small.width, 400);
    },
  );

  test('non-images are refused', () {
    expect(compressPhoto(Uint8List.fromList([1, 2, 3])), isNull);
    expect(compressPhoto(Uint8List(0)), isNull);
  });
}
