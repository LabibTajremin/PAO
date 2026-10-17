import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// What the customer picked on a service page (C09, C44).
class Selection {
  /// Creates a selection.
  const Selection({this.items = const {}, this.day, this.minutes});

  /// Quantity per sub-service ID.
  final Map<String, int> items;

  /// Start date of a hire, as a Dhaka calendar day.
  final DateTime? day;

  /// Start time of a hire, minutes after midnight in Dhaka.
  final int? minutes;

  /// The hire start as a UTC instant, once both parts are chosen.
  DateTime? get start {
    final d = day;
    final m = minutes;
    if (d == null || m == null) return null;
    return DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).add(Duration(minutes: m)).subtract(dhakaOffset);
  }
}

/// Why a selection cannot go on to the providers yet.
enum SelectionProblem {
  /// Nothing chosen.
  empty,

  /// A hire without a start.
  noStart,

  /// A hire starting in the past.
  pastStart,
}

/// The sub-services of [service] a customer can pick.
List<SubService> bookable(Service service) => [
  for (final s in service.subServices ?? const <SubService>[])
    if (s.published) s,
];

/// The fixed price of [items] on [service], in paisa.
int totalOf(Service service, Map<String, int> items) =>
    bookable(service).fold(0, (sum, s) => sum + s.price * (items[s.id] ?? 0));

/// What stops [selection] from going on, or null when it can.
SelectionProblem? problemOf(
  Service service,
  Selection selection,
  DateTime now,
) {
  if (selection.items.isEmpty) return SelectionProblem.empty;
  if (service.serviceModel != ServiceModel.durationHire) return null;
  final start = selection.start;
  if (start == null) return SelectionProblem.noStart;
  return start.isAfter(now) ? null : SelectionProblem.pastStart;
}

/// The booking draft carried on to the providers (C10).
BookingDraft draftOf(Service service, Selection selection) => BookingDraft(
  serviceId: service.id,
  items: selection.items,
  scheduledAt: selection.start?.toIso8601String(),
);
