import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/shared/booking_draft.dart';

void main() {
  test('a draft survives the query round trip', () {
    const draft = BookingDraft(serviceId: 's1', items: {'a': 2, 'b': 1});
    final full = draft.withProvider('p1');
    expect(draft.toQuery(), {'service': 's1', 'items': 'a:2,b:1'});
    final back = BookingDraft.fromQuery(full.toQuery())!;
    expect(
      [back.serviceId, back.items, back.providerId, back.scheduledAt],
      [
        's1',
        {'a': 2, 'b': 1},
        'p1',
        null,
      ],
    );
    const hire = BookingDraft(
      serviceId: 's2',
      scheduledAt: '2026-10-10T04:00Z',
    );
    expect(
      BookingDraft.fromQuery(hire.toQuery())!.scheduledAt,
      hire.scheduledAt,
    );
  });

  test('a query without a service or with bad items is cleaned up', () {
    expect(BookingDraft.fromQuery({}), isNull);
    expect(BookingDraft.fromQuery({'service': ''}), isNull);
    final draft = BookingDraft.fromQuery({
      'service': 's1',
      'items': 'a:2,b,c:x,:3,d:0,e:1',
    })!;
    expect(draft.items, {'a': 2, 'e': 1});
  });
}
