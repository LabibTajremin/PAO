import 'package:pao_api/pao_api.dart';

/// How far ahead the dashboard warns about expiring documents; matches the
/// first reminder the server sends (P-11).
const expiryWarning = Duration(days: 30);

/// Document state that changes the dashboard (M15b).
class DocumentNotice {
  /// Creates the notice.
  const DocumentNotice({this.paused = false, this.expiresAt});

  /// Requests are paused until a document is renewed (PRD §8.5).
  final bool paused;

  /// The earliest expiry within [expiryWarning], if any.
  final DateTime? expiresAt;
}

/// Reads [status] as of [now].
DocumentNotice documentNotice(VerificationStatus? status, DateTime now) {
  if (status == null) return const DocumentNotice();
  final soon =
      status.items
          .map((i) => i.expiresAt)
          .nonNulls
          .where((at) => at.difference(now) < expiryWarning)
          .toList()
        ..sort();
  return DocumentNotice(
    paused:
        !status.canReceiveBookings ||
        status.items.any((i) => i.status == ItemStatus.expired),
    expiresAt: soon.firstOrNull,
  );
}
