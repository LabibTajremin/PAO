import 'package:pao_api/pao_api.dart';

/// One priced line of a bill: a booked item, an extra or a chosen
/// sub-service before booking.
class BillLine {
  /// Creates a line.
  const BillLine({
    required this.id,
    required this.name,
    required this.quantity,
    required this.total,
    this.extra = false,
  });

  /// A line copied onto the booking.
  BillLine.of(BookingItem item)
    : this(
        id: item.subServiceId,
        name: item.name,
        quantity: item.quantity,
        total: item.total,
        extra: item.extra,
      );

  /// Sub-service ID.
  final String id;

  /// Sub-service name.
  final LocalizedText name;

  /// How many.
  final int quantity;

  /// Price of the line in paisa.
  final int total;

  /// Added during the job.
  final bool extra;
}

/// The chosen [items] priced from [service]'s catalog; unknown or unpublished
/// sub-services are dropped because they can no longer be booked.
List<BillLine> draftLines(Service service, Map<String, int> items) => [
  for (final sub in service.subServices ?? const <SubService>[])
    if (sub.published && items.containsKey(sub.id))
      BillLine(
        id: sub.id,
        name: sub.name,
        quantity: items[sub.id]!,
        total: sub.price * items[sub.id]!,
      ),
];

/// The sum of [lines].
int billTotal(List<BillLine> lines) =>
    lines.fold(0, (sum, line) => sum + line.total);
