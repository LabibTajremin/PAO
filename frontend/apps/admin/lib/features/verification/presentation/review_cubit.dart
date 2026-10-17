import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/verification/domain/verification_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Something the review page reacts to once, e.g. with a message.
sealed class ReviewOutcome {
  const ReviewOutcome();
}

/// A decision was saved; the provider is now at [level].
final class Decided extends ReviewOutcome {
  /// Creates the outcome.
  const Decided(this.level);

  /// The provider's level after the decision.
  final int level;
}

/// The next provider to review, or null when nobody else is waiting.
final class NextProvider extends ReviewOutcome {
  /// Creates the outcome.
  const NextProvider(this.id);

  /// Provider ID, or null.
  final String? id;
}

/// One provider's review (A06) and the decision in flight.
class ReviewState {
  /// Creates the state.
  const ReviewState({
    this.view = const ViewLoading(),
    this.focused,
    this.busy = false,
    this.failure,
    this.outcome,
  });

  /// The review as last loaded or returned by a decision.
  final ViewState<VerificationReview> view;

  /// The pending item the keyboard shortcuts act on.
  final ItemType? focused;

  /// A request is in flight.
  final bool busy;

  /// Why the last action failed.
  final AppFailure? failure;

  /// What the last action produced; set only on the state it happened in.
  final ReviewOutcome? outcome;

  /// The loaded review, if any.
  VerificationReview? get review => switch (view) {
    ViewData(:final data) => data,
    _ => null,
  };
}

/// Items still waiting for a decision, in review order.
List<ItemType> pendingOf(VerificationReview review) => [
  for (final i in review.items)
    if (i.status == ItemStatus.pending) i.type,
];

/// Loads a provider's review and decides its items.
class ReviewCubit extends Cubit<ReviewState> {
  /// Creates the cubit for [_id]; call [load] to start.
  ReviewCubit(this._repo, this._id) : super(const ReviewState());

  final VerificationRepository _repo;
  final String _id;

  /// Loads the review, showing loading first.
  Future<void> load() async {
    emit(const ReviewState());
    try {
      final review = await _repo.review(_id);
      if (!isClosed) _show(review);
    } on Object catch (e) {
      if (!isClosed) emit(ReviewState(view: ViewFailure(AppFailure.from(e))));
    }
  }

  /// Makes [type] the item the shortcuts act on.
  void focus(ItemType type) =>
      emit(ReviewState(view: state.view, focused: type, busy: state.busy));

  /// Moves the focus [by] pending items, staying within the list.
  void move(int by) {
    final review = state.review;
    final pending = review == null ? const <ItemType>[] : pendingOf(review);
    if (pending.isEmpty) return;
    final at = pending.indexOf(state.focused ?? pending.first) + by;
    focus(pending[at.clamp(0, pending.length - 1)]);
  }

  /// Approves [type].
  Future<void> approve(ItemType type) =>
      _decide(type, () => _repo.approve(_id, type));

  /// Rejects [type] with [reason].
  Future<void> reject(ItemType type, String reason) =>
      _decide(type, () => _repo.reject(_id, type, reason));

  /// Looks up the next provider waiting in the queue.
  Future<void> next() async {
    emit(ReviewState(view: state.view, focused: state.focused, busy: true));
    ReviewOutcome? outcome;
    AppFailure? failure;
    try {
      outcome = NextProvider(await _repo.next(_id));
    } on Object catch (e) {
      failure = AppFailure.from(e);
    }
    if (isClosed) return;
    emit(
      ReviewState(
        view: state.view,
        focused: state.focused,
        failure: failure,
        outcome: outcome,
      ),
    );
  }

  Future<void> _decide(
    ItemType type,
    Future<VerificationReview> Function() action,
  ) async {
    emit(ReviewState(view: state.view, focused: type, busy: true));
    try {
      final review = await action();
      if (!isClosed) _show(review, after: type, outcome: Decided(review.level));
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        ReviewState(
          view: state.view,
          focused: type,
          failure: AppFailure.from(e),
        ),
      );
    }
  }

  void _show(
    VerificationReview review, {
    ItemType? after,
    ReviewOutcome? outcome,
  }) => emit(
    ReviewState(
      view: ViewData(review),
      focused: _nextFocus(review, after),
      outcome: outcome,
    ),
  );

  // After a decision the decided item leaves the pending list; the focus
  // moves to the next pending item so the verifier can keep pressing keys.
  ItemType? _nextFocus(VerificationReview review, ItemType? after) {
    final pending = pendingOf(review);
    if (pending.isEmpty) return null;
    final order = review.items.map((i) => i.type).toList();
    final from = after == null ? 0 : order.indexOf(after);
    return pending.firstWhere(
      (t) => order.indexOf(t) >= from,
      orElse: () => pending.first,
    );
  }
}
