import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/jobs/domain/jobs_repository.dart';
import 'package:pao_partner/features/jobs/domain/paged.dart';
import 'package:pao_partner/features/jobs/presentation/paged_cubit.dart';
import 'package:pao_partner/features/jobs/presentation/report_cubit.dart';

class _Reports implements ReportRepository {
  AppFailure? fail;
  final uploaded = <Uint8List>[];
  ProblemReport? filed;

  @override
  Future<String> uploadPhoto(Uint8List bytes) async {
    uploaded.add(bytes);
    return 'media-${uploaded.length}';
  }

  @override
  Future<String> report(String bookingId, ProblemReport report) async {
    if (fail != null) throw fail!;
    filed = report;
    return 'TCK-1';
  }
}

void main() {
  test('paged cubit loads, appends pages and keeps rows on failure', () async {
    final pages = <String?, Paged<int>>{
      null: const Paged([1, 2], 'c2'),
      'c2': const Paged([3]),
    };
    AppFailure? fail;
    final cubit = PagedCubit<int>((cursor) async {
      if (fail != null) throw fail;
      return pages[cursor]!;
    });
    expect(cubit.state.loading, isTrue);
    await cubit.load();
    expect(
      [cubit.state.items, cubit.state.next],
      [
        [1, 2],
        'c2',
      ],
    );
    fail = const NetworkFailure();
    await cubit.more();
    expect(
      [cubit.state.items, cubit.state.next, cubit.state.failure!.code],
      [
        [1, 2],
        'c2',
        'NETWORK',
      ],
    );
    fail = null;
    await cubit.more();
    expect(
      [cubit.state.items, cubit.state.next],
      [
        [1, 2, 3],
        null,
      ],
    );
    await cubit.more();
    expect(cubit.state.items, [1, 2, 3]);
    await cubit.close();
  });

  test('paged cubit ignores replies after it closes', () async {
    final cubit = PagedCubit<int>((_) async => const Paged([1]));
    final pending = cubit.load();
    await cubit.close();
    await pending;
    final failing = PagedCubit<int>((_) async => throw const NetworkFailure());
    final failed = failing.load();
    await failing.close();
    await failed;
    expect(failing.state.failure, isNull);
  });

  test('report cubit validates, caps photos and files the report', () async {
    final repo = _Reports();
    final cubit = ReportCubit(repo, 'b1');
    await cubit.submit('short');
    expect(
      [cubit.state.missingReason, cubit.state.badDescription],
      [true, true],
    );
    cubit
      ..choose(ComplaintReason.payment)
      ..addPhoto(null);
    for (var i = 0; i < 6; i++) {
      cubit.addPhoto(Uint8List(i + 1));
    }
    expect([cubit.state.photos.length, cubit.state.canAddPhoto], [5, false]);
    cubit.removePhoto(0);
    await cubit.submit('x' * 1001);
    expect(cubit.state.badDescription, isTrue);
    repo.fail = const ApiFailure('NOT_FOUND', status: 404);
    await cubit.submit('  The customer refused to pay.  ');
    expect(
      [cubit.state.failure!.code, cubit.state.ticket],
      ['NOT_FOUND', null],
    );
    repo.fail = null;
    await cubit.submit('The customer refused to pay.');
    expect(cubit.state.ticket, 'TCK-1');
    expect(repo.filed!.reason, ComplaintReason.payment);
    expect(repo.filed!.description, 'The customer refused to pay.');
    expect(repo.filed!.photoIds.length, 4);
    await cubit.close();
  });
}
