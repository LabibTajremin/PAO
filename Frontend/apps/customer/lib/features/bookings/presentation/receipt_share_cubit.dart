import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/bookings/domain/bookings_repository.dart';

/// Sharing a receipt as a PDF (C64).
class ReceiptShareState {
  /// Creates the state.
  const ReceiptShareState({this.busy = false, this.failed = false});

  /// The PDF is being made or handed over.
  final bool busy;

  /// The last attempt failed.
  final bool failed;
}

/// Renders the receipt and hands it to the share sheet.
class ReceiptShareCubit extends Cubit<ReceiptShareState> {
  /// Creates the cubit; [render] makes the PDF and [share] sends it on.
  ReceiptShareCubit({
    required this.render,
    required this.share,
    required this.fileName,
  }) : super(const ReceiptShareState());

  /// Makes the PDF.
  final Future<Uint8List> Function(Receipt receipt) render;

  /// Hands the file over.
  final ShareFile share;

  /// Names the file.
  final String Function(Receipt receipt) fileName;

  /// Shares [receipt] once; repeated taps while busy are ignored.
  Future<void> shareReceipt(Receipt receipt) async {
    if (state.busy) return;
    emit(const ReceiptShareState(busy: true));
    final failure = await attempt(
      () async => await share(await render(receipt), fileName(receipt)),
    );
    if (!isClosed) emit(ReceiptShareState(failed: failure != null));
  }
}
