import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
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

/// The brand artwork on a receipt: the logo tile and the faint wordmark, as
/// SVG text.
typedef ReceiptArt = ({String logo, String watermark});

/// Reads [ReceiptArt] from `pao_ui`'s assets in [bundle] (the app's own by
/// default).
Future<ReceiptArt> loadReceiptArt([AssetBundle? bundle]) async {
  final assets = bundle ?? rootBundle;
  Future<String> read(String name) =>
      assets.loadString('packages/pao_ui/assets/brand/$name');
  return (
    logo: await read('logo-tile-light.svg'),
    watermark: await read('watermark.svg'),
  );
}

/// The file name a shared receipt gets.
String receiptFileName(Receipt receipt) => 'PAO-receipt-${receipt.number}.pdf';

/// Renders [receipt] as an A5 PDF with the logo, a watermark behind the
/// items and the English [tagline]; [art] defaults to the bundled artwork.
Future<Uint8List> receiptPdf(
  Receipt receipt, {
  ReceiptArt? art,
  String tagline = AppLook.seedTaglineEn,
}) async {
  final a = art ?? await loadReceiptArt();
  final doc = pw.Document(title: receiptFileName(receipt), author: 'PAO')
    ..addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (_) => pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.SvgImage(svg: a.watermark, width: 300),
              ),
            ),
            _body(receipt, a, tagline),
          ],
        ),
      ),
    );
  return await doc.save();
}

pw.Widget _body(Receipt receipt, ReceiptArt art, String tagline) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.SvgImage(svg: art.logo, width: 40),
    pw.SizedBox(height: 8),
    pw.Text(_t.bookingsReceiptNumber(receipt.number)),
    pw.Text(_t.bookingsReceiptCompleted(formatDhaka(receipt.completedAt))),
    pw.SizedBox(height: 16),
    ..._facts(receipt),
    pw.Divider(),
    ..._lines(receipt),
    pw.Divider(),
    _row(_t.bookingsTotal, _money(receipt.total), bold: true),
    pw.SizedBox(height: 16),
    pw.Text(_t.bookingsPaymentCod),
    pw.Text(_t.bookingsPaidCash),
    pw.Text(_t.bookingsReceiptThanks),
    pw.Spacer(),
    pw.Center(child: pw.Text(tagline)),
  ],
);

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
