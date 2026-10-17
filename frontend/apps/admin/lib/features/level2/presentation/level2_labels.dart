import 'package:flutter/widgets.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Status of a session.
String sessionStatusLabel(AdminL10n t, Level2SessionStatusEnum status) =>
    switch (status) {
      Level2SessionStatusEnum.scheduled => t.level2StatusScheduled,
      Level2SessionStatusEnum.completed => t.level2StatusCompleted,
      Level2SessionStatusEnum.cancelled => t.level2StatusCancelled,
    };

/// Outcome of a session.
String resultLabel(AdminL10n t, Level2Result result) => switch (result) {
  Level2Result.pass => t.level2ResultPass,
  Level2Result.fail => t.level2ResultFail,
  Level2Result.retest => t.level2ResultRetest,
};

/// Badge colour of an outcome.
PaoTone resultTone(Level2Result result) => switch (result) {
  Level2Result.pass => PaoTone.success,
  Level2Result.fail => PaoTone.danger,
  Level2Result.retest => PaoTone.warning,
};

/// Readable labels of a session row; IDs stand in for unknown names.
extension Level2RowText on BuildContext {
  /// The provider's name or short ID.
  String providerOf(Level2Row row) =>
      row.providerName ?? shortId(row.session.providerId);

  /// The service's name or short ID.
  String serviceOf(Level2Row row) => switch (row.serviceName) {
    final name? => local(name),
    null => shortId(row.session.serviceId),
  };

  /// [failure] worded for the admin; the shared messages for these codes
  /// address the provider.
  String? level2Failure(AppFailure? failure) => switch (failure?.code) {
    'LEVEL2_NOT_ELIGIBLE' => t.level2NotEligible,
    'LEVEL2_COOLING_OFF' => t.level2CoolingOff,
    _ => failureText(failure),
  };
}
