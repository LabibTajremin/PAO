import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/jobs/domain/jobs_repository.dart';

/// The report form (M25).
class ReportState {
  /// Creates the state.
  const ReportState({
    this.reason,
    this.photos = const [],
    this.sending = false,
    this.missingReason = false,
    this.badDescription = false,
    this.failure,
    this.ticket,
  });

  /// The chosen reason.
  final ComplaintReason? reason;

  /// Photos to attach, already compressed.
  final List<Uint8List> photos;

  /// Photos are uploading or the report is being filed.
  final bool sending;

  /// Submitted without a reason.
  final bool missingReason;

  /// The description is not 10–1000 characters.
  final bool badDescription;

  /// Why sending failed.
  final AppFailure? failure;

  /// Support ticket number once filed.
  final String? ticket;

  /// Whether another photo may be added.
  bool get canAddPhoto => photos.length < ReportCubit.maxPhotos;

  /// A copy with changes; validation flags and [failure] are reset.
  ReportState copyWith({
    ComplaintReason? reason,
    List<Uint8List>? photos,
    bool? sending,
    bool missingReason = false,
    bool badDescription = false,
    AppFailure? failure,
    String? ticket,
  }) => ReportState(
    reason: reason ?? this.reason,
    photos: photos ?? this.photos,
    sending: sending ?? this.sending,
    missingReason: missingReason,
    badDescription: badDescription,
    failure: failure,
    ticket: ticket ?? this.ticket,
  );
}

/// Validates the report, uploads its photos and files it.
class ReportCubit extends Cubit<ReportState> {
  /// Creates the cubit for [_bookingId].
  ReportCubit(this._repo, this._bookingId) : super(const ReportState());

  /// Most photos one report may carry (API limit).
  static const maxPhotos = 5;

  final ReportRepository _repo;
  final String _bookingId;

  /// Picks [reason].
  void choose(ComplaintReason reason) => emit(state.copyWith(reason: reason));

  /// Adds a photo; a cancelled capture passes null.
  void addPhoto(Uint8List? photo) {
    if (photo == null || !state.canAddPhoto) return;
    emit(state.copyWith(photos: [...state.photos, photo]));
  }

  /// Removes the photo at [index].
  void removePhoto(int index) =>
      emit(state.copyWith(photos: [...state.photos]..removeAt(index)));

  /// Uploads the photos and files the report with [description].
  Future<void> submit(String description) async {
    final text = description.trim();
    final reason = state.reason;
    final badText = text.length < 10 || text.length > 1000;
    if (reason == null || badText) {
      return emit(
        state.copyWith(missingReason: reason == null, badDescription: badText),
      );
    }
    emit(state.copyWith(sending: true));
    String? ticket;
    final failure = await attempt(() async {
      final ids = [for (final p in state.photos) await _repo.uploadPhoto(p)];
      ticket = await _repo.report(
        _bookingId,
        ProblemReport(reason: reason, description: text, photoIds: ids),
      );
    });
    emit(state.copyWith(sending: false, failure: failure, ticket: ticket));
  }
}
