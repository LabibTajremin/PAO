import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/data/api_places.dart';

Map<String, Object?> _place(String title, {String? area}) => {
  'id': 'n1',
  'kind': 'place',
  'title': title,
  'area': ?area,
  'location': {'lat': 23.79, 'lng': 90.4},
};

void main() {
  late Dio dio;
  late DioAdapter mock;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    mock = DioAdapter(dio: dio);
  });

  test('search asks PAO in the chosen language', () async {
    mock.onGet(
      '/v1/places/search',
      queryParameters: {'q': 'banani', 'lang': 'bn'},
      (s) => s.reply(200, {
        'items': [_place('বনানী', area: 'Banani'), _place('Road 11')],
      }),
    );
    final found = await ApiPlacesService(dio).search('banani', language: 'bn');
    expect(found.map((p) => (p.title, p.area)), [
      ('বনানী', 'Banani'),
      ('Road 11', null),
    ]);
    expect((found.first.point.lat, found.first.point.lng), (23.79, 90.4));
  });

  test('reverse names the pin, and nothing near or outside is null', () async {
    final places = ApiPlacesService(dio);
    mock.onGet(
      '/v1/places/reverse',
      queryParameters: {'lat': 23.79, 'lng': 90.4, 'lang': 'en'},
      (s) => s.reply(200, _place('Square Hospital', area: 'Dhanmondi')),
    );
    final here = await places.reverse(const GeoPoint(23.79, 90.4));
    expect(here?.title, 'Square Hospital');
    for (final status in [404, 422]) {
      mock.onGet(
        '/v1/places/reverse',
        queryParameters: {'lat': 22.3, 'lng': 91.8, 'lang': 'en'},
        (s) => s.reply(status, {'code': 'X'}),
      );
      expect(await places.reverse(const GeoPoint(22.3, 91.8)), isNull);
    }
    mock.onGet(
      '/v1/places/reverse',
      queryParameters: {'lat': 1.0, 'lng': 2.0, 'lang': 'en'},
      (s) => s.reply(500, {'code': 'INTERNAL'}),
    );
    await expectLater(
      places.reverse(const GeoPoint(1, 2)),
      throwsA(isA<DioException>()),
    );
  });
}
