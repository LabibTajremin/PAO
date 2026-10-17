import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/level2/presentation/level2_labels.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';

void main() {
  test('every status and result has a label and a colour', () async {
    for (final locale in ['en', 'bn']) {
      final t = await AdminL10n.delegate.load(Locale(locale));
      final labels = [
        for (final s in Level2SessionStatusEnum.values)
          sessionStatusLabel(t, s),
        for (final r in Level2Result.values) resultLabel(t, r),
      ];
      expect(labels.toSet(), hasLength(6), reason: locale);
    }
    expect(Level2Result.values.map(resultTone).toSet(), hasLength(3));
  });
}
