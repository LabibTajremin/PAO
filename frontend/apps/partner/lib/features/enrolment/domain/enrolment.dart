/// The wizard steps M05–M13 in order; [key] is the API's step name, also used
/// in the `/enrol/:step` route.
enum EnrolStep {
  /// M05.
  personal('personal'),

  /// M06.
  services('services'),

  /// M07.
  area('area'),

  /// M08.
  nid('nid'),

  /// M09.
  selfie('selfie'),

  /// M10.
  policeClearance('police_clearance'),

  /// M11, optional for Level 1.
  skillProof('skill_proof'),

  /// M12.
  emergencyContact('emergency_contact'),

  /// M13.
  codeOfConduct('code_of_conduct');

  EnrolStep(this.key);

  /// API and route name.
  final String key;

  /// The step named [key], or null for anything else.
  static EnrolStep? parse(String key) {
    for (final step in values) {
      if (step.key == key) return step;
    }
    return null;
  }
}

/// Completion of one step.
class StepProgress {
  /// Creates the entry.
  const StepProgress(this.step, {required this.done, required this.required});

  /// The step.
  final EnrolStep step;

  /// Saved on the server.
  final bool done;

  /// Needed for Level 1.
  final bool required;
}

/// Where the provider is in the wizard (resumable from the server).
class EnrolProgress {
  /// Creates the progress.
  const EnrolProgress({
    required this.steps,
    required this.complete,
    required this.submitted,
  });

  /// Completion per step.
  final List<StepProgress> steps;

  /// Every required step is done.
  final bool complete;

  /// Sent for verification.
  final bool submitted;

  /// Whether [step] is saved.
  bool isDone(EnrolStep step) => steps.any((s) => s.step == step && s.done);

  /// The first required step still to do; null when nothing is missing.
  EnrolStep? get firstIncomplete {
    for (final s in steps) {
      if (s.required && !s.done) return s.step;
    }
    return null;
  }

  /// The step to show after [current]: the next unsaved one in order, so the
  /// optional skill proof is still offered, else any required gap.
  EnrolStep? nextAfter(EnrolStep current) {
    for (final step in EnrolStep.values.skip(current.index + 1)) {
      if (!isDone(step)) return step;
    }
    return firstIncomplete;
  }
}

/// A service the provider may offer (M06).
class ServiceOption {
  /// Creates the option.
  const ServiceOption({required this.id, required this.en, required this.bn});

  /// Service ID.
  final String id;

  /// English name.
  final String en;

  /// Bangla name.
  final String bn;

  /// The name in [languageCode].
  String name(String languageCode) => languageCode == 'bn' ? bn : en;
}

/// How a photo is taken.
enum PhotoMode {
  /// Rear camera, e.g. the NID card.
  camera,

  /// Front camera for the live selfie.
  selfie,

  /// A saved photo or scan.
  gallery,
}

/// Version of the code of conduct text shown in M13; stored with the
/// acceptance (PRD §6.2 item 9).
const conductVersion = '2026-10';

/// The calendar date in Bangladesh (UTC+6 all year) at [now].
DateTime dhakaToday(DateTime now) {
  final dhaka = now.toUtc().add(const Duration(hours: 6));
  return DateTime(dhaka.year, dhaka.month, dhaka.day);
}

/// Whether someone born on [birth] is 18 on [today] (PRD §6.2, backend rule).
bool isAdult(DateTime birth, DateTime today) =>
    !DateTime(birth.year + 18, birth.month, birth.day).isAfter(today);

/// Whether [number] has the 10, 13 or 17 digits of a Bangladeshi NID.
bool validNid(String number) =>
    RegExp(r'^(\d{10}|\d{13}|\d{17})$').hasMatch(number);
