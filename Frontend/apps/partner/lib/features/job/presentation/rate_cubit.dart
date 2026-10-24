import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/job/domain/job_repository.dart';

/// Rating the customer (M21).
class RateState {
  /// Creates the state.
  const RateState({
    this.stars = 0,
    this.tags = const {},
    this.busy = false,
    this.failure,
    this.done = false,
  });

  /// 0 until a star is tapped.
  final int stars;

  /// Picked tags.
  final Set<ReviewTag> tags;

  /// Sending.
  final bool busy;

  /// Why sending failed.
  final AppFailure? failure;

  /// Sent.
  final bool done;

  /// A copy with changes; [failure] is replaced, not kept.
  RateState copyWith({
    int? stars,
    Set<ReviewTag>? tags,
    bool? busy,
    AppFailure? failure,
    bool? done,
  }) => RateState(
    stars: stars ?? this.stars,
    tags: tags ?? this.tags,
    busy: busy ?? this.busy,
    failure: failure,
    done: done ?? this.done,
  );
}

/// Collects stars, tags and a comment, then sends the review.
class RateCubit extends Cubit<RateState> {
  /// Creates the cubit for booking [_id].
  RateCubit(this._repo, this._id) : super(const RateState());

  final JobRepository _repo;
  final String _id;

  /// Tags a provider may give a customer.
  static const List<ReviewTag> tags = [
    ReviewTag.polite,
    ReviewTag.clearInstructions,
    ReviewTag.paidPromptly,
    ReviewTag.safePlace,
    ReviewTag.rude,
    ReviewTag.unclearInstructions,
    ReviewTag.unsafePlace,
  ];

  /// Sets the stars.
  void rate(int stars) => emit(state.copyWith(stars: stars));

  /// Adds or removes [tag].
  void toggle(ReviewTag tag) {
    final next = {...state.tags};
    if (!next.remove(tag)) next.add(tag);
    emit(state.copyWith(tags: next));
  }

  /// Sends the review with [comment]; nothing happens before a star is set.
  Future<void> submit(String comment) async {
    if (state.stars == 0) return;
    emit(state.copyWith(busy: true));
    final failure = await attempt(
      () => _repo.review(
        _id,
        CustomerReview(
          stars: state.stars,
          tags: state.tags,
          comment: comment.trim(),
        ),
      ),
    );
    emit(state.copyWith(busy: false, failure: failure, done: failure == null));
  }
}
