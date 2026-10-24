import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/verification/presentation/document_viewer.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

Widget _picture(String url) => Text('picture $url');

void main() {
  testWidgets('the selfie opens beside the NID front with signed URLs', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(
        '/v1/admin/verifications/$rahim',
        (s) => s.reply(200, reviewJson()),
      )
      ..onGet(
        '/v1/admin/documents/m-selfie/view-url',
        (s) => s.reply(200, {
          'url': 'https://files.test/selfie',
          'expiresAt': '2026-10-09T04:05:00Z',
        }),
      )
      ..onGet(
        '/v1/admin/documents/m-front/view-url',
        (s) => s.reply(403, apiError('FORBIDDEN')),
      );
    await h.pumpApp(tester, Routes.reviewOf(rahim));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey(ItemType.selfie)),
        matching: find.text('Open documents'),
      ),
    );
    await h.settle(tester);
    expect(find.text('Selfie'), findsNothing);
    expect(find.text('Live selfie'), findsWidgets);
    expect(find.text('NID front'), findsWidgets);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('You are not allowed to do this.'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await h.settle(tester);
    expect(find.byType(DocumentsDialog), findsNothing);
  });

  testWidgets('documents zoom, rotate and retry a failed link', (tester) async {
    narrow(tester);
    final repo = FakeVerificationRepository();
    await pumpPage(
      tester,
      DocumentsDialog(
        title: 'National ID',
        repo: repo,
        image: _picture,
        documents: const [(mediaId: 'm-front', label: 'NID front')],
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('picture https://x/m-front'), findsOneWidget);
    expect(find.text('100% · 0°'), findsOneWidget);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(find.text('150% · 0°'), findsOneWidget);
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.tap(find.byTooltip('Rotate right'));
    await tester.pump();
    expect(find.text('100% · 90°'), findsOneWidget);
    await tester.tap(find.byTooltip('Rotate left'));
    await tester.tap(find.byTooltip('Rotate left'));
    await tester.pump();
    expect(find.text('100% · 270°'), findsOneWidget);
  });

  testWidgets('a failed link can be retried', (tester) async {
    final repo = FakeVerificationRepository()..error = const NetworkFailure();
    await pumpPage(
      tester,
      DocumentsDialog(
        title: 'Selfie',
        repo: repo,
        image: _picture,
        documents: const [(mediaId: 'm-selfie', label: 'Selfie')],
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    repo.error = null;
    await tester.tap(find.text('Try again'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('picture https://x/m-selfie'), findsOneWidget);
  });

  testWidgets('a picture that cannot load says so', (tester) async {
    await pumpPage(
      tester,
      Builder(
        builder: (context) => Column(
          children: [
            brokenDocument(context, Exception('x'), null),
            SizedBox(height: 50, child: networkDocument('https://x/y')),
          ],
        ),
      ),
    );
    expect(find.text('This document could not be shown.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
