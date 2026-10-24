import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/features/verification/presentation/labels.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';

void main() {
  testWidgets('every value has a label in both languages', (tester) async {
    late BuildContext context;
    await pumpPage(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    for (final locale in ['en', 'bn']) {
      final t = await AdminL10n.delegate.load(Locale(locale));
      final labels = [
        for (final v in ItemType.values) itemLabel(t, v),
        for (final v in ItemStatus.values) statusLabel(t, v),
        for (final v in [0, 1, 2]) levelLabel(t, v),
        for (final v in [null, ...VerificationReviewFaceMatchEnum.values])
          faceLabel(t, v),
        for (final v in Gender.values) genderLabel(t, v),
        for (final k in ['nid_front', 'nid_back', 'selfie'])
          documentLabel(t, k),
        for (final k in ['police_clearance', 'skill_proof'])
          documentLabel(t, k),
        for (final k in ['issueDate', 'workingRadiusM', 'services', 'homeLat'])
          fieldLabel(t, k),
        for (final k in ['homeLng', 'name', 'relation', 'phone'])
          fieldLabel(t, k),
        ...rejectTemplates(t),
      ];
      expect(labels.every((l) => l.isNotEmpty), isTrue, reason: locale);
    }
    expect(
      [null, ...VerificationReviewFaceMatchEnum.values].map(faceColor).toSet(),
      hasLength(4),
    );
    expect(ItemStatus.values.map(statusTone).toSet(), hasLength(4));
    expect([1, 30, 60].map(waitedColor), [
      PaoColors.textPrimary,
      PaoColors.warning,
      PaoColors.danger,
    ]);
    expect(context.lang, 'en');
    expect(shortId('0123456789'), '01234567');
    expect(shortId('abc'), 'abc');
  });
}
