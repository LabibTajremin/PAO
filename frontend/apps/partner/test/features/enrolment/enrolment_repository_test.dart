import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_partner/features/enrolment/data/api_enrolment_repository.dart';
import 'package:pao_partner/features/enrolment/data/photo_capture.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';

import '../../support/harness.dart';
import 'fakes.dart';

/// A catalog with one published and one hidden service.
Map<String, Object?> catalogJson() {
  Map<String, Object?> service(String id, {required bool published}) => {
    'id': id,
    'categoryId': 'c1',
    'name': {'en': 'Electrician $id', 'bn': 'ইলেকট্রিশিয়ান $id'},
    'iconKey': 'bolt',
    'serviceModel': 'on_demand',
    'requiredLevel': 1,
    'searchRadiusM': 5000,
    'womenProvidersOnly': false,
    'requiresLevel2': false,
    'published': published,
  };
  return {
    'version': 3,
    'categories': [
      {
        'id': 'c1',
        'name': {'en': 'Repairs', 'bn': 'মেরামত'},
        'iconKey': 'plug',
        'sortOrder': 1,
        'published': true,
        'services': [
          service('s1', published: true),
          service('s2', published: false),
        ],
      },
    ],
  };
}

void main() {
  const base = '/v1/provider/enrolment';

  test('reads progress and the published services', () async {
    final h = await Harness.create();
    final repo = ApiEnrolmentRepository(h.services.api);
    h.http
      ..onGet(base, (s) => s.reply(200, enrolmentJson(done: {EnrolStep.nid})))
      ..onGet('/v1/provider/catalog', (s) => s.reply(200, catalogJson()));
    expect((await repo.progress()).isDone(EnrolStep.nid), isTrue);
    final options = await repo.serviceOptions();
    expect([for (final o in options) o.id], ['s1']);
    expect(options.single.name('bn'), 'ইলেকট্রিশিয়ান s1');
  });

  test('sends every step in the shape the API expects', () async {
    final h = await Harness.create();
    final repo = ApiEnrolmentRepository(h.services.api);
    final inputs = <String, (StepInput, Object)>{
      'personal': (
        PersonalDetails(
          fullName: 'Rahim Uddin',
          dateOfBirth: DateTime(1990, 4, 12),
          gender: Gender.male,
          presentAddress: 'Banani, Dhaka',
          permanentAddress: 'Sherpur, Bogura',
        ),
        {
          'fullName': 'Rahim Uddin',
          'dateOfBirth': '1990-04-12',
          'gender': 'male',
          'presentAddress': 'Banani, Dhaka',
          'permanentAddress': 'Sherpur, Bogura',
        },
      ),
      'services': (
        const ServiceChoice(serviceIds: ['s1'], experienceYears: 8),
        {
          'serviceIds': ['s1'],
          'experienceYears': 8,
        },
      ),
      'area': (
        const WorkArea(lat: 23.79, lng: 90.4, radiusM: 8000),
        {
          'homeBase': {'lat': 23.79, 'lng': 90.4},
          'workingRadiusM': 8000,
        },
      ),
      'nid': (
        const NidDetails(number: '1234567890', frontId: 'f', backId: 'b'),
        {'nidNumber': '1234567890', 'frontMediaId': 'f', 'backMediaId': 'b'},
      ),
      'selfie': (const SelfiePhoto('s'), {'mediaId': 's'}),
      'police-clearance': (
        PoliceClearance(mediaId: 'p', issueDate: DateTime(2026, 6)),
        {'mediaId': 'p', 'issueDate': '2026-06-01'},
      ),
      'skill-proof': (
        const SkillProof(['k1', 'k2']),
        {
          'mediaIds': ['k1', 'k2'],
        },
      ),
      'emergency-contact': (
        const EmergencyContact(
          name: 'Karim',
          relation: 'Brother',
          phone: '01812345678',
        ),
        {'name': 'Karim', 'relation': 'Brother', 'phone': '01812345678'},
      ),
      'code-of-conduct': (
        const ConductAcceptance(),
        {'version': conductVersion, 'accepted': true},
      ),
    };
    for (final MapEntry(key: path, value: (input, body)) in inputs.entries) {
      h.http.onPut(
        '$base/$path',
        (s) => s.reply(200, enrolmentJson(done: {input.step})),
        data: Matchers.any,
      );
      final p = await repo.save(input);
      expect(p.isDone(input.step), isTrue, reason: path);
      expect(h.bodyOf('$base/$path'), body, reason: path);
    }
  });

  test('verifies the contact, submits and uploads', () async {
    final h = await Harness.create();
    final storage = Dio();
    DioAdapter(dio: storage).onPut(
      'http://s3.test/obj',
      (s) => s.reply(200, null),
      data: Matchers.any,
    );
    final repo = ApiEnrolmentRepository(h.services.api, storage: storage);
    h.http
      ..onPost(
        '$base/emergency-contact/verify',
        (s) => s.reply(200, enrolmentJson(done: {EnrolStep.emergencyContact})),
        data: Matchers.any,
      )
      ..onPost('$base/submit', (s) => s.reply(200, verification()))
      ..onPost(
        '/v1/provider/uploads',
        (s) => s.reply(201, {
          'mediaId': 'm1',
          'uploadUrl': 'http://s3.test/obj',
          'headers': <String, String>{},
          'expiresAt': '2026-10-09T10:00:00Z',
        }),
        data: Matchers.any,
      )
      ..onPost(
        '/v1/provider/uploads/m1/confirm',
        (s) => s.reply(200, {
          'id': 'm1',
          'purpose': 'nid_front',
          'contentType': 'image/jpeg',
          'sizeBytes': 4,
          'status': 'confirmed',
        }),
      );
    final p = await repo.verifyContact('123456');
    expect(p.isDone(EnrolStep.emergencyContact), isTrue);
    expect(h.bodyOf('$base/emergency-contact/verify'), {'code': '123456'});
    await repo.submit();
    expect(await repo.upload(tinyPng, 'nid_front', onProgress: (_) {}), 'm1');
    expect((h.bodyOf('/v1/provider/uploads')! as Map)['purpose'], 'nid_front');
  });

  test('photos come from the camera, front camera or gallery', () async {
    final h = await Harness.create();
    final photo = XFile.fromData(tinyPng);
    when(
      () => h.picker.pickImage(
        source: ImageSource.camera,
        // The stub must name the argument PhotoSource passes to match it.
        // ignore: avoid_redundant_argument_values
        preferredCameraDevice: CameraDevice.rear,
      ),
    ).thenAnswer((_) async => photo);
    when(
      () => h.picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      ),
    ).thenAnswer((_) async => photo);
    when(() => h.picker.pickImage(source: ImageSource.gallery))
        .thenAnswer((_) async => null);
    final photos = h.services.photos;
    expect(await capturePhoto(photos, PhotoMode.camera), isNotNull);
    expect(await capturePhoto(photos, PhotoMode.selfie), isNotNull);
    expect(await capturePhoto(photos, PhotoMode.gallery), isNull);
  });
}
