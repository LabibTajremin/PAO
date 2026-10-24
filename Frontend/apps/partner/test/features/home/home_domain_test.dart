import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/home/data/prefs_online_memory.dart';
import 'package:pao_partner/features/home/domain/documents.dart';
import 'package:pao_partner/features/home/domain/home_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../job/job_fixtures.dart';

final _now = DateTime.utc(2026, 10, 9, 4);

VerificationStatus _status({
  bool cleared = true,
  List<Map<String, Object?>> items = const [],
}) => VerificationStatus.fromJson({
  'level': 1,
  'badge': 'verified',
  'items': items,
  'canReceiveBookings': cleared,
});

Map<String, Object?> _item(String status, [String? expiresAt]) => {
  'type': 'police_clearance',
  'status': status,
  'required': true,
  'expiresAt': ?expiresAt,
};

void main() {
  test('the active job is the one furthest along', () {
    BookingSummary row(String id, String status) =>
        BookingSummary.fromJson(summary(id: id, status: status));
    expect(activeJob([]), isNull);
    expect(
      activeJob([
        row('a', 'accepted'),
        row('b', 'arrived'),
        row('c', 'requested'),
      ])!.id,
      'b',
    );
    expect(activeJob([row('a', 'accepted')])!.id, 'a');
  });

  test('document notices: paused, expiring soon or nothing', () {
    expect(documentNotice(null, _now).paused, isFalse);
    expect(documentNotice(_status(cleared: false), _now).paused, isTrue);
    final expired = documentNotice(
      _status(items: [_item('expired', '2026-10-01T00:00:00Z')]),
      _now,
    );
    expect([expired.paused, expired.expiresAt], [true, DateTime.utc(2026, 10)]);
    final soon = documentNotice(
      _status(
        items: [
          _item('approved', '2027-06-01T00:00:00Z'),
          _item('approved', '2026-10-30T00:00:00Z'),
          _item('approved', '2026-10-20T00:00:00Z'),
          _item('approved'),
        ],
      ),
      _now,
    );
    expect([soon.paused, soon.expiresAt], [false, DateTime.utc(2026, 10, 20)]);
  });

  test('the online choice survives in preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final memory = PrefsOnlineMemory(await Prefs.open());
    expect(memory.online, isFalse);
    await memory.remember(online: true);
    expect(memory.online, isTrue);
  });
}
