import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart' hide Gender;
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/data/step_requests.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment_repository.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/shared/uploads.dart';

/// [EnrolmentRepository] on the PAO API.
class ApiEnrolmentRepository implements EnrolmentRepository {
  /// Creates the repository; [storage] sends upload PUTs (tests mock it).
  ApiEnrolmentRepository(this._dio, {Dio? storage})
    : _api = ProviderEnrolmentApi(_dio),
      _uploader = providerUploader(_dio, storage: storage);

  final Dio _dio;
  final ProviderEnrolmentApi _api;
  final MediaUploader _uploader;

  @override
  Future<EnrolProgress> progress() async =>
      progressOf((await _api.getEnrolment()).data!);

  @override
  Future<List<ServiceOption>> serviceOptions() async {
    final tree = (await ProviderApi(_dio).getProviderCatalog()).data!;
    return [
      for (final category in tree.categories)
        for (final service in category.services)
          if (service.published)
            ServiceOption(
              id: service.id,
              en: service.name.en,
              bn: service.name.bn,
            ),
    ];
  }

  @override
  Future<EnrolProgress> save(StepInput input) async =>
      progressOf(await sendStep(_dio, input));

  @override
  Future<EnrolProgress> verifyContact(String code) async {
    final res = await _api.verifyEmergencyContact(
      emergencyContactVerifyInput: EmergencyContactVerifyInput(code: code),
    );
    return progressOf(res.data!);
  }

  @override
  Future<String> upload(
    Uint8List bytes,
    String purpose, {
    void Function(double progress)? onProgress,
  }) => _uploader.upload(
    UploadFile(bytes: bytes, purpose: purpose),
    onProgress: onProgress,
  );

  @override
  Future<void> submit() => _api.submitEnrolment();
}

/// Maps the API's step list onto the wizard.
EnrolProgress progressOf(EnrolmentStatus status) => EnrolProgress(
  steps: [
    for (final s in status.steps)
      StepProgress(
        EnrolStep.parse(s.step.value)!,
        done: s.done,
        required: s.required_,
      ),
  ],
  complete: status.complete,
  submitted: status.submitted,
);
