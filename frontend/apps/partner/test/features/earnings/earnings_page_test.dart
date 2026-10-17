import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/jobs/presentation/job_detail_page.dart';

import '../../support/harness.dart';
import '../jobs/fixtures.dart';

Map<String, Object?> _summary(String period) => period == 'day'
    ? {
        'period': 'day',
        'from': '2026-10-09',
        'to': '2026-10-09',
        'total': 0,
        'jobs': 0,
        'buckets': [
          {'date': '2026-10-09', 'total': 0, 'jobs': 0},
        ],
      }
    : {
        'period': period,
        'from': '2026-10-04',
        'to': '2026-10-10',
        'total': 226000,
        'jobs': 2,
        'buckets': [
          {'date': '2026-10-08', 'total': 113000, 'jobs': 1},
          {'date': '2026-10-09', 'total': 113000, 'jobs': 1},
        ],
      };

Map<String, Object?> _job(String number) => {
  'bookingId': bookingId,
  'number': number,
  'completedAt': '2026-10-09T08:00:00Z',
  'serviceName': named('Fan repair'),
  'total': 113000,
};

void main() {
  Future<Harness> start(WidgetTester tester) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    return h;
  }

  testWidgets('shows totals per period, the daily breakdown and jobs', (
    tester,
  ) async {
    final h = await start(tester);
    h.http
      ..onGet(
        '/v1/provider/earnings/summary',
        (s) => s.replyCallback(
          200,
          (o) => _summary(o.queryParameters['period'] as String),
        ),
      )
      ..onGet(
        '/v1/provider/earnings/jobs',
        (s) => s.replyCallback(
          200,
          (o) => o.queryParameters['cursor'] == null
              ? {
                  'items': [_job('PAO-1')],
                  'nextCursor': 'c2',
                }
              : {
                  'items': [_job('PAO-2')],
                },
        ),
      );
    await h.pumpApp(tester, Routes.earnings);
    expect(find.text('4 Oct – 10 Oct 2026'), findsOneWidget);
    expect(find.text('৳2,260'), findsOneWidget);
    expect(find.text('2 jobs'), findsOneWidget);
    expect(find.text('Thu, 8 Oct'), findsOneWidget);
    expect(find.text('1 job'), findsNWidgets(2));
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.textContaining('PAO-2 · 9 Oct 2026'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await h.settle(tester);
    expect(find.text('9 Oct 2026'), findsOneWidget);
    expect(find.text('0 jobs'), findsOneWidget);
    expect(find.text('Thu, 8 Oct'), findsNothing);
    expect(h.sent.last.queryParameters['period'], 'day');
    await tester.tap(find.text('This month'));
    await h.settle(tester);
    expect(h.sent.last.queryParameters['period'], 'month');
    await tester.tap(find.textContaining('PAO-1'));
    await h.settle(tester);
    expect(find.byType(JobDetailPage), findsOneWidget);
  });

  testWidgets('no earnings yet', (tester) async {
    final h = await start(tester);
    h.http
      ..onGet(
        '/v1/provider/earnings/summary',
        (s) => s.reply(200, _summary('week')),
      )
      ..onGet(
        '/v1/provider/earnings/jobs',
        (s) => s.reply(200, {'items': <Object?>[]}),
      );
    await h.pumpApp(tester, Routes.earnings);
    expect(find.text('No earnings yet'), findsOneWidget);
    final sent = h.sent.lastWhere(
      (o) => o.path == '/v1/provider/earnings/jobs',
    );
    expect(sent.queryParameters, containsPair('from', isA<String>()));
  });

  testWidgets('a failed summary fails the period list too; retry', (
    tester,
  ) async {
    final h = await start(tester);
    h.http
      ..onGet(
        '/v1/provider/earnings/summary',
        (s) => s.reply(500, apiError('INTERNAL')),
      )
      ..onGet(
        '/v1/provider/earnings/jobs',
        (s) => s.reply(200, {'items': <Object?>[]}),
      );
    await h.pumpApp(tester, Routes.earnings);
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsWidgets,
    );
    h.http.onGet(
      '/v1/provider/earnings/summary',
      (s) => s.reply(200, _summary('week')),
    );
    await tester.tap(find.text('Try again').first);
    await h.settle(tester);
    expect(find.text('৳2,260'), findsOneWidget);
  });
}
