import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/bookings/data/receipt_pdf.dart';
import 'package:pao_customer/features/bookings/data/share_pdf.dart';
import 'package:pao_customer/features/bookings/presentation/receipt_page.dart';
import 'package:pao_customer/features/bookings/presentation/receipt_share_cubit.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _path = '/v1/customer/bookings/b1/receipt';

Receipt _receipt({String? area = 'Banani'}) => Receipt.fromJson(
  jsonDecode(jsonEncode(receipt(area: area))) as Map<String, dynamic>,
);

void main() {
  setUpAll(initializeDateFormatting);

  test('the receipt renders as a PDF named after its number', () async {
    final bytes = await receiptPdf(_receipt());
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(await receiptPdf(_receipt(area: null)), isNotEmpty);
    expect(receiptFileName(_receipt()), 'PAO-receipt-PAO-104233.pdf');
  });

  test('sharing hands the PDF to the platform share sheet', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    final temp = Directory.systemTemp.createTempSync('pao');
    addTearDown(() => temp.deleteSync(recursive: true));
    messenger
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => temp.path,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async {
          calls.add(call);
          return 'dev.fluttercommunity.plus/share/unavailable';
        },
      );
    await sharePdf(Uint8List.fromList([1, 2, 3]), 'r.pdf');
    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['mimeTypes'], ['application/pdf']);
  });

  test('a second tap while sharing is ignored', () async {
    final done = Completer<void>();
    var shared = 0;
    final cubit = ReceiptShareCubit(
      render: (_) async => Uint8List(1),
      share: (_, _) async {
        shared++;
        await done.future;
      },
      fileName: (_) => 'r.pdf',
    );
    final first = cubit.shareReceipt(_receipt());
    await Future<void>.delayed(Duration.zero);
    await cubit.shareReceipt(_receipt());
    expect(cubit.state.busy, isTrue);
    done.complete();
    await first;
    expect([shared, cubit.state.failed], [1, false]);
    await cubit.close();
  });

  testWidgets('the receipt loads, retries and shares as a PDF (C64)', (
    tester,
  ) async {
    tall(tester);
    final h = await Harness.create();
    final shared = <String>[];
    var fail = true;
    h.http.onGet(_path, (s) => s.reply(500, apiError('INTERNAL')));
    await pumpPage(
      tester,
      ReceiptPage(
        services: h.services,
        bookingId: 'b1',
        share: (bytes, name) async {
          if (fail) throw const FileSystemException('no space');
          shared.add(name);
        },
      ),
    );
    await h.settle(tester);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(_path, (s) => s.reply(200, receipt()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Receipt PAO-104233'), findsOneWidget);
    expect(find.text('Completed 9 Oct 2026, 12:30 PM'), findsOneWidget);
    expect(find.text('Nusrat Jahan'), findsOneWidget);
    expect(find.text('Banani'), findsOneWidget);
    expect(find.text('৳2,000.50'), findsOneWidget);
    await tester.tap(find.text('Share as PDF'));
    await h.settle(tester);
    expect(
      find.text('Could not share the receipt. Please try again.'),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(find.text('Share as PDF'));
    await h.settle(tester);
    expect(shared, ['PAO-receipt-PAO-104233.pdf']);
  });
}
