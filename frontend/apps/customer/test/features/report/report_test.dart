import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_customer/features/report/data/api_report_repository.dart';
import 'package:pao_customer/features/report/domain/report_repository.dart';
import 'package:pao_customer/features/report/presentation/report_cubit.dart';

import '../../support/harness.dart';
import '../bookings/fixtures.dart';

class _Repo implements ReportRepository {
  final uploads = <Uint8List>[];
  final reports = <ProblemReport>[];
  AppFailure? error;
  Completer<void>? gate;

  @override
  Future<String> uploadPhoto(Uint8List bytes) async {
    uploads.add(bytes);
    return 'm${uploads.length}';
  }

  @override
  Future<String> report(String bookingId, ProblemReport report) async {
    await gate?.future;
    if (error case final AppFailure e) throw e;
    reports.add(report);
    return 'TCK-000001';
  }
}

const _description = 'The fan still wobbles after the visit.';

void main() {
  test('the cubit validates, limits photos and files the report', () async {
    final repo = _Repo();
    final cubit = ReportCubit(repo, 'b1');
    await cubit.submit('short');
    expect(
      [cubit.state.missingReason, cubit.state.badDescription],
      [true, true],
    );
    cubit
      ..choose(ComplaintReason.poorQuality)
      ..addPhoto(null);
    for (var i = 0; i < 6; i++) {
      cubit.addPhoto(Uint8List.fromList([i]));
    }
    expect(cubit.state.photos, hasLength(5));
    expect(cubit.state.canAddPhoto, isFalse);
    cubit.removePhoto(0);
    await cubit.submit('x' * 1001);
    expect(cubit.state.badDescription, isTrue);
    repo.error = const NetworkFailure();
    await cubit.submit(_description);
    expect(cubit.state.failure!.code, 'NETWORK');
    repo
      ..error = null
      ..gate = Completer();
    final sending = cubit.submit(' $_description ');
    await cubit.submit(_description);
    repo.gate!.complete();
    await sending;
    expect(cubit.state.ticket, 'TCK-000001');
    expect(repo.reports.single.photoIds, ['m5', 'm6', 'm7', 'm8']);
    expect(repo.reports.single.description, _description);
    await cubit.close();
  });

  test(
    'the repository uploads complaint photos and files the report',
    () async {
      final h = await Harness.create();
      final storage = Dio();
      DioAdapter(dio: storage)
          .onPut('u', (s) => s.reply(200, null), data: Matchers.any);
      final repo = ApiReportRepository(
        h.services.api,
        uploader: MediaUploader(
          create: (f) async {
            expect(f.purpose, 'complaint_photo');
            return const SignedUpload(mediaId: 'm1', url: 'u');
          },
          confirm: (_) async {},
          storage: storage,
        ),
      );
      h.http.onPost(
        '/v1/customer/bookings/b1/reports',
        (s) => s.reply(201, {
          'id': 'c1',
          'ticketNumber': 'TCK-000002',
          'bookingId': 'b1',
          'reporterRole': 'customer',
          'reporterId': 'r1',
          'reason': 'damage',
          'description': _description,
          'status': 'open',
          'createdAt': '2026-10-09T04:00:00Z',
        }),
      );
      expect(await repo.uploadPhoto(tinyPng), 'm1');
      const report = ProblemReport(
        reason: ComplaintReason.damage,
        description: _description,
      );
      expect(await repo.report('b1', report), 'TCK-000002');
      expect(h.bodyOf('/v1/customer/bookings/b1/reports'), {
        'reason': 'damage',
        'description': _description,
      });
      expect(ApiReportRepository(h.services.api), isA<ReportRepository>());
    },
  );

  testWidgets('a customer reports a problem with photos and gets a ticket', (
    tester,
  ) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    when(() => h.picker.pickImage(source: ImageSource.camera))
        .thenAnswer((_) async => XFile.fromData(tinyPng));
    when(() => h.picker.pickImage(source: ImageSource.gallery))
        .thenAnswer((_) async => XFile.fromData(tinyPng));
    await h.pumpApp(tester, Routes.booking(bookingId, 'report'));
    await tester.tap(find.text('Send report'));
    await h.settle(tester);
    expect(find.text('Choose a reason.'), findsOneWidget);
    expect(find.text('Write 10 to 1000 characters.'), findsOneWidget);
    await tester.tap(find.text('Poor quality work'));
    await tester.enterText(find.byType(TextField), _description);
    await tester.tap(find.text('Take photo'));
    await h.settle(tester);
    await tester.tap(find.text('Choose photo'));
    await h.settle(tester);
    expect(find.text('Photos (2 of 5)'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove photo').first);
    await h.settle(tester);
    expect(find.text('Photos (1 of 5)'), findsOneWidget);
    h.http.onPost(
      '/v1/customer/uploads',
      (s) => s.reply(422, apiError('UPLOAD_INVALID')),
    );
    await tester.tap(find.text('Send report'));
    await h.settle(tester);
    expect(
      find.text('This file cannot be used. Try another photo.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Remove photo'));
    await h.settle(tester);
    h.http.onPost(
      '/v1/customer/bookings/$bookingId/reports',
      (s) => s.reply(201, {
        'id': 'c1',
        'ticketNumber': 'TCK-000003',
        'bookingId': bookingId,
        'reporterRole': 'customer',
        'reporterId': 'r1',
        'reason': 'poor_quality',
        'description': _description,
        'status': 'open',
        'createdAt': '2026-10-09T04:00:00Z',
      }),
    );
    await tester.tap(find.text('Send report'));
    await h.settle(tester);
    expect(find.text('Report sent'), findsOneWidget);
    expect(find.textContaining('TCK-000003'), findsOneWidget);
    h.http.onGet(
      '/v1/customer/bookings/$bookingId',
      (s) => s.reply(200, booking()),
    );
    await tester.tap(find.text('Back to booking'));
    await h.settle(tester);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });
}
