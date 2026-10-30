import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/location/data/google_places.dart';
import 'package:pao_customer/features/location/domain/places.dart';

const _url = 'https://maps.googleapis.com/maps/api/geocode/json';

Map<String, Object?> _result(String title, List<String> types) => {
  'formatted_address': title,
  'geometry': {
    'location': {'lat': 23.79, 'lng': 90},
  },
  'address_components': [
    {
      'long_name': 'Dhaka',
      'types': ['locality'],
    },
    {'long_name': 'Banani', 'types': types},
  ],
};

void main() {
  test('the environment picks the adapter', () {
    expect(placesFromEnvironment(), isA<NoPlacesService>());
    expect(placesFromEnvironment(key: 'k'), isA<GooglePlacesService>());
  });

  test('geocoding results become places', () async {
    final dio = Dio();
    final sent = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          sent.add(o);
          h.next(o);
        },
      ),
    );
    final http = DioAdapter(
      dio: dio,
      matcher: const UrlRequestMatcher(matchMethod: true),
    );
    final places = GooglePlacesService(dio, 'key-1');
    http.onGet(
      _url,
      (s) => s.reply(200, {
        'status': 'OK',
        'results': [
          _result('Road 11, Banani', ['sublocality', 'political']),
          _result('Banani Lake', ['neighborhood']),
          _result('Somewhere', ['route']),
          {'formatted_address': 'broken'},
          {
            'formatted_address': 'No parts',
            'geometry': {
              'location': {'lat': 1, 'lng': 2},
            },
            'address_components': null,
          },
        ],
      }),
    );
    final found = await places.search('Banani', language: 'bn');
    expect(found.map((p) => p.area), ['Banani', 'Banani', null, null]);
    expect(found.first.point.lng, 90.0);
    expect(sent.last.queryParameters, {
      'address': 'Banani',
      'components': 'country:BD',
      'language': 'bn',
      'region': 'bd',
      'key': 'key-1',
    });
    final here = await places.reverse(const GeoPoint(23.7, 90.4));
    expect(here!.title, 'Road 11, Banani');
    expect(sent.last.queryParameters['latlng'], '23.7,90.4');
  });

  test('no results mean nothing found', () async {
    final dio = Dio();
    DioAdapter(
      dio: dio,
      matcher: const UrlRequestMatcher(matchMethod: true),
    ).onGet(_url, (s) => s.reply(200, {'status': 'ZERO_RESULTS'}));
    final places = GooglePlacesService(dio, 'k');
    expect(await places.search('zzz'), isEmpty);
    expect(await places.reverse(const GeoPoint(0, 0)), isNull);
  });
}
