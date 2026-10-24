/// What the customer chose before booking (C09 → C10 → C11 → C12), carried in
/// the route's query so a restored or deep-linked screen keeps it.
class BookingDraft {
  /// Creates a draft.
  const BookingDraft({
    required this.serviceId,
    this.items = const {},
    this.providerId,
    this.scheduledAt,
  });

  /// The service being booked.
  final String serviceId;

  /// Quantity per sub-service ID.
  final Map<String, int> items;

  /// The chosen provider.
  final String? providerId;

  /// Start chosen on the service page (driver hire, C44), ISO 8601 UTC.
  final String? scheduledAt;

  /// A copy with [providerId] chosen.
  BookingDraft withProvider(String id) => BookingDraft(
    serviceId: serviceId,
    items: items,
    providerId: id,
    scheduledAt: scheduledAt,
  );

  /// The draft as query parameters.
  Map<String, String> toQuery() => {
    'service': serviceId,
    if (items.isNotEmpty)
      'items': [for (final e in items.entries) '${e.key}:${e.value}'].join(','),
    'provider': ?providerId,
    'at': ?scheduledAt,
  };

  /// Reads a draft from [query]; null without a service.
  static BookingDraft? fromQuery(Map<String, String> query) {
    final service = query['service'];
    if (service == null || service.isEmpty) return null;
    final items = <String, int>{};
    for (final pair in (query['items'] ?? '').split(',')) {
      final [id, qty] = [...pair.split(':'), '', ''].take(2).toList();
      final n = int.tryParse(qty);
      if (id.isNotEmpty && n != null && n > 0) items[id] = n;
    }
    return BookingDraft(
      serviceId: service,
      items: items,
      providerId: query['provider'],
      scheduledAt: query['at'],
    );
  }
}
