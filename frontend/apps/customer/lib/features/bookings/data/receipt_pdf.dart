import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// The PDF is always English: the built-in PDF fonts have no Bengali glyphs
// or shaping, and a receipt is often forwarded to people outside the app.
final CustomerL10n _t = lookupCustomerL10n(const Locale('en'));

String _money(int paisa) {
  final format = NumberFormat.decimalPatternDigits(
    locale: 'en',
    decimalDigits: paisa % 100 == 0 ? 0 : 2,
  );
  return 'BDT ${format.format(paisa / 100)}';
}

/// The file name a shared receipt gets.
String receiptFileName(Receipt receipt) => 'PAO-receipt-${receipt.number}.pdf';

/// Renders [receipt] as an A5 PDF.
Future<Uint8List> receiptPdf(Receipt receipt) async {
  final doc = pw.Document(title: receiptFileName(receipt), author: 'PAO')
    ..addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PAO', style: const pw.TextStyle(fontSize: 24)),
            pw.Text(_t.bookingsReceiptNumber(receipt.number)),
            pw.Text(
              _t.bookingsReceiptCompleted(formatDhaka(receipt.completedAt)),
            ),
            pw.SizedBox(height: 16),
            ..._facts(receipt),
            pw.Divider(),
            ..._lines(receipt),
            pw.Divider(),
            _row(_t.bookingsTotal, _money(receipt.total), bold: true),
            pw.SizedBox(height: 16),
            pw.Text(_t.bookingsPaidCash),
            pw.Text(_t.bookingsReceiptThanks),
          ],
        ),
      ),
    );
  return await doc.save();
}

List<pw.Widget> _facts(Receipt r) => [
  _row(_t.bookingsReceiptService, r.serviceName.en),
  _row(_t.bookingsReceiptProvider, r.providerName),
  _row(_t.bookingsReceiptCustomer, r.customerName),
  if (r.area case final String area) _row(_t.bookingsReceiptArea, area),
];

List<pw.Widget> _lines(Receipt r) => [
  for (final item in r.items)
    _row(
      '${item.name.en} x ${item.quantity}${item.extra ? ' *' : ''}',
      _money(item.total),
    ),
  if (r.items.any((i) => i.extra)) pw.Text('* ${_t.bookingsExtra}'),
];

pw.Widget _row(String label, String value, {bool bold = false}) {
  final style = bold
      ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
      : null;
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.Text(value, style: style),
      ],
    ),
  );
}
