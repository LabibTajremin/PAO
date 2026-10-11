import 'package:flutter/widgets.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// How a service is sold (PRD §4).
String modelLabel(AdminL10n t, ServiceModel model) => switch (model) {
  ServiceModel.onDemand => t.catalogModelOnDemand,
  ServiceModel.durationHire => t.catalogModelDuration,
  ServiceModel.listing => t.catalogModelListing,
  ServiceModel.partnerReferral => t.catalogModelPartner,
};

/// What one quantity of a sub-service means.
String unitLabel(AdminL10n t, PriceUnit unit) => switch (unit) {
  PriceUnit.job => t.catalogUnitJob,
  PriceUnit.unit => t.catalogUnitUnit,
  PriceUnit.hour => t.catalogUnitHour,
  PriceUnit.day => t.catalogUnitDay,
};

/// A verification level a service requires.
String levelName(AdminL10n t, int level) => switch (level) {
  0 => t.dashLevel0,
  1 => t.dashLevel1,
  _ => t.dashLevel2,
};

/// Whether customers can see an item.
class PublishedBadge extends StatelessWidget {
  /// Creates the badge.
  const PublishedBadge({required this.published, super.key});

  /// The item is visible to customers.
  final bool published;

  @override
  Widget build(BuildContext context) => PaoBadge(
    label: published ? context.t.catalogPublished : context.t.catalogHidden,
    tone: published ? PaoTone.success : PaoTone.neutral,
  );
}
