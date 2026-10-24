import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/verification/presentation/review_cubit.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

import 'fixtures.dart';

VerificationReview _review(List<Map<String, Object?>> items, {int level = 0}) =>
    VerificationReview.fromJson(reviewJson(items: items, level: level));

void main() {
  late FakeVerificationRepository repo;
  late ReviewCubit cubit;

  setUp(() {
    repo = FakeVerificationRepository();
    cubit = ReviewCubit(repo, rahim);
  });

  tearDown(() => cubit.close());

  test('loading focuses the first pending item', () async {
    await cubit.load();
    expect(cubit.state.review, isNotNull);
    expect(cubit.state.focused, ItemType.nid);
    expect(pendingOf(cubit.state.review!), [ItemType.nid, ItemType.selfie]);
  });

  test('a failed load shows the failure', () async {
    repo.error = const NetworkFailure();
    await cubit.load();
    expect(cubit.state.view, isA<ViewFailure<VerificationReview>>());
    expect(cubit.state.review, isNull);
  });

  test('the focus moves within the pending items', () async {
    cubit.move(1);
    expect(cubit.state.focused, isNull);
    await cubit.load();
    cubit.move(1);
    expect(cubit.state.focused, ItemType.selfie);
    cubit.move(5);
    expect(cubit.state.focused, ItemType.selfie);
    cubit.move(-3);
    expect(cubit.state.focused, ItemType.nid);
    cubit.focus(ItemType.selfie);
    expect(cubit.state.focused, ItemType.selfie);
    repo.current = _review([item('nid', status: 'approved')]);
    await cubit.load();
    cubit.move(1);
    expect(cubit.state.focused, isNull);
  });

  test('a decision moves the focus on and reports the level', () async {
    await cubit.load();
    repo.current = _review([
      item('nid', status: 'approved'),
      item('selfie'),
      item('address'),
    ]);
    await cubit.approve(ItemType.nid);
    expect(repo.calls, ['approve nid']);
    expect(cubit.state.focused, ItemType.selfie);
    expect((cubit.state.outcome! as Decided).level, 0);
    repo.current = _review([
      item('nid'),
      item('selfie', status: 'rejected'),
      item('address', status: 'approved'),
    ], level: 1);
    await cubit.reject(ItemType.selfie, 'Blurry photo');
    expect(repo.calls.last, 'reject selfie Blurry photo');
    // Nothing pending after the selfie, so the focus wraps to the first.
    expect(cubit.state.focused, ItemType.nid);
    expect((cubit.state.outcome! as Decided).level, 1);
  });

  test('a failed decision keeps the review and shows why', () async {
    await cubit.load();
    repo.error = const ApiFailure('ITEM_NOT_PENDING', status: 409);
    await cubit.approve(ItemType.selfie);
    expect(cubit.state.failure!.code, 'ITEM_NOT_PENDING');
    expect(cubit.state.review, isNotNull);
    expect(cubit.state.busy, isFalse);
  });

  test('next finds another provider, nobody, or fails', () async {
    await cubit.load();
    await cubit.next();
    expect((cubit.state.outcome! as NextProvider).id, karim);
    repo.nextId = null;
    await cubit.next();
    expect((cubit.state.outcome! as NextProvider).id, isNull);
    repo.error = const NetworkFailure();
    await cubit.next();
    expect(cubit.state.outcome, isNull);
    expect(cubit.state.failure!.code, 'NETWORK');
  });

  test('results arriving after close are dropped', () async {
    for (final error in [null, const NetworkFailure()]) {
      final loading = ReviewCubit(repo..error = error, rahim);
      final load = loading.load();
      await loading.close();
      await load;
      final deciding = ReviewCubit(repo..error = null, rahim);
      await deciding.load();
      repo.error = error;
      final approve = deciding.approve(ItemType.nid);
      final next = deciding.next();
      await deciding.close();
      await Future.wait([approve, next]);
      expect(deciding.state.busy, isTrue);
    }
  });
}
