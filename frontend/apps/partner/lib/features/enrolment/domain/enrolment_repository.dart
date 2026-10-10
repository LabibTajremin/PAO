import 'dart:typed_data';

import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';

/// The enrolment wizard on the server (P-02).
abstract interface class EnrolmentRepository {
  /// Completion per step.
  Future<EnrolProgress> progress();

  /// Services the provider may choose.
  Future<List<ServiceOption>> serviceOptions();

  /// Saves one step.
  Future<EnrolProgress> save(StepInput input);

  /// Confirms the emergency contact with the [code] texted to them.
  Future<EnrolProgress> verifyContact(String code);

  /// Uploads a photo for [purpose] (e.g. `nid_front`) and returns its media
  /// ID; [onProgress] gets 0–1.
  Future<String> upload(
    Uint8List bytes,
    String purpose, {
    void Function(double progress)? onProgress,
  });

  /// Sends every completed step for verification.
  Future<void> submit();
}
