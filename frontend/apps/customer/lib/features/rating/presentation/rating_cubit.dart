import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/rating/domain/rating_repository.dart';

/// Rating the provider (C17) and the thanks screen (C55).
class RatingState {
  /// Creates the state.
  const RatingState({
    this.view = const ViewLoading(),
    this.stars = 0,
    this.tags = const {},
    this.busy = false,
    this.failure,
    this.done = false,
  });

  /// The booking, for the provider's name.
  final ViewState<Booking> view;

  /// 0 until a star is tapped.
  final int stars;

  /// Picked tags.
  final Set<ReviewTag> tags;

  /// Sending.
  final bool busy;

  /// Why sending failed.
  final AppFailure? failure;

  /// Rated, now or before; the thanks screen shows.
  final bool done;

  /// A copy with changes; [failure] is replaced, not kept.
  RatingState copyWith({
    ViewState<Booking>? view,
    int? stars,
    Set<ReviewTag>? tags,
    bool busy = false,
    AppFailure? failure,
    bool? done,
  }) => RatingState(
    view: view ?? this.view,
    stars: stars ?? this.stars,
    tags: tags ?? this.tags,
    busy: busy,
    failure: failure,
    done: done ?? this.done,
  );
}

/// Collects stars, tags and a comment, then sends the review.
class RatingCubit extends Cubit<RatingState> {
  /// Creates the cubit for booking [_id].
  RatingCubit(this._repo, this._id) : super(const RatingState());

  final RatingRepository _repo;
  final String _id;

  /// Tags a customer may give a provider, praise first.
  static const List<ReviewTag> tags = [
    ReviewTag.onTime,
    ReviewTag.professional,
    ReviewTag.qualityWork,
    ReviewTag.clean,
    ReviewTag.friendly,
    ReviewTag.fairPrice,
    ReviewTag.late_,
    ReviewTag.rude,
    ReviewTag.poorQuality,
    ReviewTag.messy,
  ];

  /// The API accepts at most this many tags.
  static const maxTags = 6;

  /// Loads the booking; one already rated goes straight to thanks.
  Future<void> load() async {
    emit(const RatingState());
    try {
      final b = await _repo.booking(_id);
      emit(RatingState(view: ViewData(b), done: b.reviewedByMe ?? false));
    } on Object catch (e) {
      emit(RatingState(view: ViewFailure(AppFailure.from(e))));
    }
  }

  /// Sets the stars.
  void rate(int stars) => emit(state.copyWith(stars: stars));

  /// Adds or removes [tag]; a seventh tag is ignored.
  void toggle(ReviewTag tag) {
    final next = {...state.tags};
    if (!next.remove(tag) && next.length < maxTags) next.add(tag);
    emit(state.copyWith(tags: next));
  }

  /// Sends the review with [comment]; nothing happens before a star is set.
  Future<void> submit(String comment) async {
    if (state.stars == 0) return;
    emit(state.copyWith(busy: true));
    final failure = await attempt(
      () => _repo.review(
        _id,
        ProviderReview(
          stars: state.stars,
          tags: state.tags,
          comment: comment.trim(),
        ),
      ),
    );
    // A review sent from another device still counts as rated.
    final rated = failure?.code == 'REVIEW_ALREADY_SUBMITTED';
    emit(
      state.copyWith(
        failure: rated ? null : failure,
        done: failure == null || rated,
      ),
    );
  }
}
