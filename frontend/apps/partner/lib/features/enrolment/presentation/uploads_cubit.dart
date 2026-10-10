import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment_repository.dart';

/// Takes a photo; null when the provider cancels.
typedef Capture = Future<Uint8List?> Function(PhotoMode mode);

/// One photo on its way to storage.
class UploadSlot {
  /// Creates the slot.
  const UploadSlot({this.bytes, this.progress = 0, this.mediaId, this.failure});

  /// The photo, kept for preview and retry.
  final Uint8List? bytes;

  /// Upload progress 0–1.
  final double progress;

  /// Set once the upload is confirmed.
  final String? mediaId;

  /// Why the capture or upload failed.
  final AppFailure? failure;

  /// Whether the upload is running.
  bool get uploading => mediaId == null && failure == null;
}

/// Photos of the document steps, keyed by slot such as `nid_front` or
/// `skill_proof:2`; the part before `:` is the upload purpose.
class UploadsCubit extends Cubit<Map<String, UploadSlot>> {
  /// Creates the cubit.
  UploadsCubit(this._repo, this._capture) : super(const {});

  final EnrolmentRepository _repo;
  final Capture _capture;

  /// Takes a photo for [slot] and uploads it.
  Future<void> capture(String slot, PhotoMode mode) async {
    final Uint8List? bytes;
    try {
      bytes = await _capture(mode);
    } on Object catch (e) {
      return _put(slot, UploadSlot(failure: AppFailure.from(e)));
    }
    if (bytes != null) await _upload(slot, bytes);
  }

  /// Uploads the photo of [slot] again.
  Future<void> retry(String slot) => _upload(slot, state[slot]!.bytes!);

  /// The confirmed media ID of [slot].
  String? mediaId(String slot) => state[slot]?.mediaId;

  /// Confirmed media IDs of every slot for [purpose].
  List<String> mediaIds(String purpose) => [
    for (final MapEntry(:key, :value) in state.entries)
      if (key.split(':').first == purpose && value.mediaId != null)
        value.mediaId!,
  ];

  /// Slots for [purpose], in the order they were added.
  List<String> slots(String purpose) => [
    for (final key in state.keys)
      if (key.split(':').first == purpose) key,
  ];

  Future<void> _upload(String slot, Uint8List bytes) async {
    _put(slot, UploadSlot(bytes: bytes));
    try {
      final id = await _repo.upload(
        bytes,
        slot.split(':').first,
        onProgress: (p) => _put(slot, UploadSlot(bytes: bytes, progress: p)),
      );
      _put(slot, UploadSlot(bytes: bytes, progress: 1, mediaId: id));
    } on Object catch (e) {
      _put(slot, UploadSlot(bytes: bytes, failure: AppFailure.from(e)));
    }
  }

  // Uploads can finish after the page is gone.
  void _put(String slot, UploadSlot value) {
    if (!isClosed) emit({...state, slot: value});
  }
}
