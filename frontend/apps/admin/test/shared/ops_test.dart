import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/providers/presentation/provider_labels.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/filtered_paged_cubit.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_admin/shared/ops/record_cubit.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  final t = lookupAdminL10n(const Locale('en'));

  test('every status, reason and item has a distinct name', () {
    final names = [
      AccountStatus.values.map((s) => accountStatusLabel(t, s)),
      BookingStatus.values.map((s) => bookingStatusLabel(t, s)),
      ComplaintStatus.values.map((s) => complaintStatusLabel(t, s)),
      ComplaintReason.values.map((r) => complaintReasonLabel(t, r)),
      ItemType.values.map((i) => itemTypeLabel(t, i)),
      ItemStatus.values.map((s) => itemStatusLabel(t, s)),
      Gender.values.map((g) => genderLabel(t, g)),
      providerLevels.map((l) => levelLabel(t, l)),
    ];
    for (final group in names) {
      expect(group.toSet(), hasLength(group.length));
    }
    expect(ItemStatus.values.map(itemStatusTone).toSet(), hasLength(4));
    expect(complaintReasonLabel(t, ComplaintReason.late_), 'Late');
  });

  test('a refresh replaces the rows quietly and yields to filters', () async {
    final asked = <(String, String?)>[];
    var gate = Completer<void>();
    final cubit = FilteredPagedCubit<String, String>('all', (f, cursor) async {
      asked.add((f, cursor));
      await gate.future;
      if (f == 'boom') throw const NetworkFailure();
      return Paged(['$f-${asked.length}'], 'next');
    });
    final first = cubit.load();
    await cubit.refresh();
    expect(asked, hasLength(1), reason: 'no refresh while loading');
    gate.complete();
    await first;
    expect(cubit.state.items, ['all-1']);

    gate = Completer<void>();
    final quiet = cubit.refresh();
    expect(cubit.state.loading, isFalse);
    final applied = cubit.apply('mine');
    gate.complete();
    await Future.wait([quiet, applied]);
    expect(cubit.filter, 'mine');
    expect(cubit.state.items, ['mine-3']);

    await cubit.apply('boom');
    expect(cubit.state.failure, isA<NetworkFailure>());
    await cubit.refresh();
    expect(cubit.state.failure, isA<NetworkFailure>());
    await cubit.close();
  });

  test('an action on a closed record is reported but not shown', () async {
    final cubit = RecordCubit<int>(() async => 1);
    await cubit.load();
    final failure = await cubit.act(() async => 2);
    expect(failure, isNull);
    expect((cubit.state as ViewData<int>).data, 2);
    await cubit.close();
    expect(await cubit.act(() async => 3), isNull);
    expect(
      await cubit.act(() => Future.error(const NetworkFailure())),
      isA<NetworkFailure>(),
    );
  });
}
